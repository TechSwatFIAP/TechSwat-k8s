# =============================================================================
# RabbitMQ in-cluster (compartilhado entre Order e Payment)
# =============================================================================
# Provisiona:
#   - StatefulSet 1-replica + PVC EBS persistente   -> svc-rabbitmq :5672 / :15672
#   - Service ClusterIP (DNS interno svc-rabbitmq.nstechswat.svc.cluster.local)
#   - Secret de credenciais (default admin/admin — sobrescrever via var)
# Acionado quando var.enable_rabbitmq = true.
# Consumido por:
#   - k8s-order-service.tf   -> order_rabbitmq_host = "svc-rabbitmq"
#   - k8s-payment-service.tf -> SPRING_RABBITMQ_HOST = "svc-rabbitmq"

resource "kubectl_manifest" "rabbitmq_secret" {
  count      = var.enable_rabbitmq ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: secrets-rabbitmq
  namespace: nstechswat
type: Opaque
stringData:
  RABBITMQ_DEFAULT_USER: ${var.rabbitmq_username}
  RABBITMQ_DEFAULT_PASS: ${var.rabbitmq_password}
YAML
}

resource "kubectl_manifest" "rabbitmq_headless_service" {
  count      = var.enable_rabbitmq ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-headless
  namespace: nstechswat
  labels:
    app: rabbitmq
spec:
  selector:
    app: rabbitmq
  clusterIP: None
  ports:
    - name: amqp
      protocol: TCP
      port: 5672
      targetPort: 5672
    - name: management
      protocol: TCP
      port: 15672
      targetPort: 15672
YAML
}

resource "kubectl_manifest" "rabbitmq_statefulset" {
  count = var.enable_rabbitmq ? 1 : 0
  depends_on = [
    kubectl_manifest.rabbitmq_headless_service,
    kubectl_manifest.rabbitmq_secret,
  ]
  yaml_body = <<-YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
  namespace: nstechswat
spec:
  serviceName: rabbitmq-headless
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
            - name: amqp
              containerPort: 5672
            - name: management
              containerPort: 15672
          envFrom:
            - secretRef:
                name: secrets-rabbitmq
          volumeMounts:
            - name: data
              mountPath: /var/lib/rabbitmq
          readinessProbe:
            exec:
              command: ["rabbitmq-diagnostics", "-q", "ping"]
            initialDelaySeconds: 20
            periodSeconds: 10
            timeoutSeconds: 10
            failureThreshold: 3
          livenessProbe:
            exec:
              command: ["rabbitmq-diagnostics", "-q", "status"]
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 15
            failureThreshold: 3
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: ${var.rabbitmq_storage_size}
YAML
}

resource "kubectl_manifest" "rabbitmq_service" {
  count      = var.enable_rabbitmq ? 1 : 0
  depends_on = [kubectl_manifest.rabbitmq_statefulset]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-rabbitmq
  namespace: nstechswat
  labels:
    app: rabbitmq
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
