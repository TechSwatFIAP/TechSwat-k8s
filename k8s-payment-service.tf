# =============================================================================
# Microserviço TechSwat-Payment-Service (opcional)
# =============================================================================

resource "kubectl_manifest" "configmap_techswat_payment" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-techswat-payment
  namespace: nstechswat
data:
  MESSAGING_TRANSPORT: rabbit
  SPRING_RABBITMQ_HOST: ${var.order_rabbitmq_host}
  SPRING_RABBITMQ_PORT: "${var.order_rabbitmq_port}"
  SPRING_RABBITMQ_USERNAME: ${var.order_rabbitmq_username}
  SPRING_RABBITMQ_PASSWORD: ${var.order_rabbitmq_password}
  SPRING_DATA_MONGODB_URI: mongodb://svc-payment-mongo:27017/${var.payment_mongodb_database}
  PAYMENTS_PROVIDERS_MERCADOPAGO_STUB_ENABLED: "${var.payment_mercadopago_stub_enabled}"
  PAYMENTS_WEBHOOKS_MERCADOPAGO_SIGNATURE_REQUIRED: "false"
YAML
}

resource "kubectl_manifest" "deploy_techswat_payment" {
  count            = var.enable_payment_service ? 1 : 0
  depends_on       = [kubectl_manifest.configmap_techswat_payment, kubectl_manifest.service_payment_mongo, kubectl_manifest.service_rabbitmq]
  wait_for_rollout = false
  yaml_body        = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-techswat-payment
  namespace: nstechswat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: techswat-payment
  template:
    metadata:
      labels:
        app: techswat-payment
    spec:
      containers:
        - name: techswat-payment
          image: ${var.techswat_payment_image}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: configmap-techswat-payment
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
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

resource "kubectl_manifest" "service_techswat_payment" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.deploy_techswat_payment]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-techswat-payment
  namespace: nstechswat
spec:
  selector:
    app: techswat-payment
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
YAML
}
