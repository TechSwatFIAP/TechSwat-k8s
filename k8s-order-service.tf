# =============================================================================
# Microserviço TechSwat-Order-Service (opcional — não altera o deploy existente)
# =============================================================================

resource "kubectl_manifest" "configmap_techswat_order" {
  count      = var.enable_order_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-techswat-order
  namespace: nstechswat
data:
  SPRING_DATASOURCE_URL: jdbc:mysql://${var.mysql_endpoint}:${var.mysql_port}/${var.mysql_order_db_name}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
  SPRING_DATASOURCE_USERNAME: root
  MESSAGING_TRANSPORT: ${var.order_messaging_transport}
  SPRING_RABBITMQ_HOST: ${var.order_rabbitmq_host}
  SPRING_RABBITMQ_PORT: "${var.order_rabbitmq_port}"
  SPRING_RABBITMQ_USERNAME: ${var.order_rabbitmq_username}
  SPRING_RABBITMQ_PASSWORD: ${var.order_rabbitmq_password}
  TECHSWAT_BASE_URL: http://svc-techswat.nstechswat.svc.cluster.local
YAML
}

resource "kubectl_manifest" "secrets_techswat_order" {
  count      = var.enable_order_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: secrets-techswat-order
  namespace: nstechswat
type: Opaque
stringData:
  SPRING_DATASOURCE_PASSWORD: ${var.mysql_root_password}
  INTERNAL_API_KEY: "${var.internal_order_api_key}"
YAML
}

resource "kubectl_manifest" "deploy_techswat_order" {
  count            = var.enable_order_service ? 1 : 0
  depends_on       = [kubectl_manifest.secrets_techswat_order, kubectl_manifest.configmap_techswat_order]
  wait_for_rollout = false
  yaml_body        = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-techswat-order
  namespace: nstechswat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: techswat-order
  template:
    metadata:
      labels:
        app: techswat-order
    spec:
      containers:
        - name: techswat-order
          image: ${var.techswat_order_image}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: configmap-techswat-order
          env:
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat-order
                  key: SPRING_DATASOURCE_PASSWORD
            - name: INTERNAL_API_KEY
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat-order
                  key: INTERNAL_API_KEY
          resources:
            requests:
              cpu: "50m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "384Mi"
YAML
}

resource "kubectl_manifest" "service_techswat_order" {
  count      = var.enable_order_service ? 1 : 0
  depends_on = [kubectl_manifest.deploy_techswat_order]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-techswat-order
  namespace: nstechswat
spec:
  selector:
    app: techswat-order
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
YAML
}
