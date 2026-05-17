# =============================================================================
# Microserviço TechSwat-Stock-Service (opcional — não altera o deploy existente)
# =============================================================================

resource "kubectl_manifest" "configmap_techswat_stock" {
  count      = var.enable_stock_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-techswat-stock
  namespace: nstechswat
data:
  DB_HOST: ${var.mysql_endpoint}
  DB_PORT: "${var.mysql_port}"
  DB_USERNAME: root
  MESSAGING_TRANSPORT: rabbit
  SPRING_RABBITMQ_HOST: ${var.order_rabbitmq_host}
  SPRING_RABBITMQ_PORT: "${var.order_rabbitmq_port}"
  SPRING_RABBITMQ_USERNAME: ${var.order_rabbitmq_username}
  SERVER_PORT: "8083"
YAML
}

resource "kubectl_manifest" "secrets_techswat_stock" {
  count      = var.enable_stock_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: secrets-techswat-stock
  namespace: nstechswat
type: Opaque
stringData:
  DB_PASSWORD: ${var.mysql_root_password}
  SPRING_RABBITMQ_PASSWORD: ${var.order_rabbitmq_password}
YAML
}

resource "kubectl_manifest" "deploy_techswat_stock" {
  count            = var.enable_stock_service ? 1 : 0
  depends_on       = [kubectl_manifest.secrets_techswat_stock, kubectl_manifest.configmap_techswat_stock]
  wait_for_rollout = false
  yaml_body        = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-techswat-stock
  namespace: nstechswat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: techswat-stock
  template:
    metadata:
      labels:
        app: techswat-stock
    spec:
      containers:
        - name: techswat-stock
          image: ${var.techswat_stock_image}
          ports:
            - containerPort: 8083
          envFrom:
            - configMapRef:
                name: configmap-techswat-stock
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat-stock
                  key: DB_PASSWORD
            - name: SPRING_RABBITMQ_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat-stock
                  key: SPRING_RABBITMQ_PASSWORD
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8083
            initialDelaySeconds: 30
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8083
            initialDelaySeconds: 60
            periodSeconds: 15
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
YAML
}

resource "kubectl_manifest" "service_techswat_stock" {
  count      = var.enable_stock_service ? 1 : 0
  depends_on = [kubectl_manifest.deploy_techswat_stock]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-techswat-stock
  namespace: nstechswat
spec:
  selector:
    app: techswat-stock
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8083
  type: ClusterIP
YAML
}
