# =============================================================================
# Kubernetes Manifests
# =============================================================================

# -----------------------------------------------------------------------------
# CoreDNS Scale (deve ser aplicado primeiro após node group)
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "coredns_scale" {
  depends_on        = [aws_eks_node_group.node_group]
  wait_for_rollout  = false
  server_side_apply = true
  force_conflicts   = true
  yaml_body         = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  replicas: 1
YAML
}

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "namespace" {
  depends_on = [kubectl_manifest.coredns_scale]
  yaml_body  = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: nstechswat
YAML
}

# -----------------------------------------------------------------------------
# Secrets
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "secrets_techswat" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: secrets-techswat
  namespace: nstechswat
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: ${var.mysql_root_password}
  MYSQL_PASSWORD: ${var.mysql_root_password}
  REDIS_PASSWORD: ${var.redis_password}
  JWT_SECRET: "${var.jwt_secret}"
  INTERNAL_API_KEY: "${var.internal_order_api_key}"
YAML
}

# -----------------------------------------------------------------------------
# ConfigMap
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "configmap_techswat" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-techswat
  namespace: nstechswat
data:
  MYSQL_DATABASE: ${var.mysql_db_name}
  MYSQL_USER: techswat_user
  MYSQL_HOST: ${var.mysql_endpoint}
  MYSQL_PORT: "${var.mysql_port}"
  REDIS_HOST: ${var.redis_private_ip}
  REDIS_PORT: "6379"
  SPRING_DATASOURCE_URL: jdbc:mysql://${var.mysql_endpoint}:${var.mysql_port}/${var.mysql_db_name}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
  SPRING_DATASOURCE_USERNAME: root
  SERVER_SERVLET_CONTEXT_PATH: /
YAML
}

# -----------------------------------------------------------------------------
# Deployment
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "deploy_techswat" {
  depends_on       = [kubectl_manifest.secrets_techswat, kubectl_manifest.configmap_techswat]
  wait_for_rollout = false
  yaml_body        = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-techswat
  namespace: nstechswat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: techswat
  template:
    metadata:
      labels:
        app: techswat
    spec:
      containers:
        - name: techswat
          image: ${var.techswat_image}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: configmap-techswat
          env:
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat
                  key: MYSQL_ROOT_PASSWORD
            - name: SPRING_DATA_REDIS_HOST
              valueFrom:
                configMapKeyRef:
                  name: configmap-techswat
                  key: REDIS_HOST
            - name: SPRING_DATA_REDIS_PORT
              valueFrom:
                configMapKeyRef:
                  name: configmap-techswat
                  key: REDIS_PORT
            - name: SPRING_DATA_REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat
                  key: REDIS_PASSWORD
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat
                  key: JWT_SECRET
            - name: INTERNAL_API_KEY
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat
                  key: INTERNAL_API_KEY
            - name: ORDER_SERVICE_BASE_URL
              valueFrom:
                configMapKeyRef:
                  name: configmap-techswat
                  key: ORDER_SERVICE_BASE_URL
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
YAML
}

# -----------------------------------------------------------------------------
# Service (LoadBalancer)
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "service" {
  depends_on = [kubectl_manifest.deploy_techswat]
  yaml_body  = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-techswat
  namespace: nstechswat
spec:
  selector:
    app: techswat
  ports:
      - protocol: TCP
        port: 80
        targetPort: 8080
  type: LoadBalancer
YAML
}

# -----------------------------------------------------------------------------
# HorizontalPodAutoscaler
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "hpa_techswat" {
  depends_on = [kubectl_manifest.deploy_techswat]
  yaml_body  = <<YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-techswat
  namespace: nstechswat
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: deploy-techswat
  minReplicas: 1
  maxReplicas: 3
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
YAML
}

# -----------------------------------------------------------------------------
# Data source para obter o hostname do LoadBalancer
# -----------------------------------------------------------------------------

resource "time_sleep" "wait_for_lb" {
  depends_on      = [kubectl_manifest.service]
  create_duration = "60s"
}

data "kubernetes_service_v1" "techswat_lb" {
  depends_on = [time_sleep.wait_for_lb]
  metadata {
    name      = "svc-techswat"
    namespace = "nstechswat"
  }
}
