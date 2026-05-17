# =============================================================================
# RabbitMQ no cluster (mensageria TechSwat + microserviços)
# =============================================================================

resource "kubectl_manifest" "deploy_rabbitmq" {
  count      = var.enable_order_service || var.enable_stock_service || var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-rabbitmq
  namespace: nstechswat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
        - name: rabbitmq
          image: rabbitmq:3.13-management-alpine
          ports:
            - containerPort: 5672
              name: amqp
            - containerPort: 15672
              name: management
          env:
            - name: RABBITMQ_DEFAULT_USER
              value: ${var.order_rabbitmq_username}
            - name: RABBITMQ_DEFAULT_PASS
              value: ${var.order_rabbitmq_password}
          resources:
            requests:
              cpu: "50m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "384Mi"
YAML
}

resource "kubectl_manifest" "service_rabbitmq" {
  count      = var.enable_order_service || var.enable_stock_service || var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.deploy_rabbitmq]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-rabbitmq
  namespace: nstechswat
spec:
  selector:
    app: rabbitmq
  ports:
    - name: amqp
      protocol: TCP
      port: 5672
      targetPort: 5672
    - name: management
      protocol: TCP
      port: 15672
      targetPort: 15672
  type: ClusterIP
YAML
}
