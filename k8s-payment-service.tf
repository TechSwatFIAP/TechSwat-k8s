# =============================================================================
# Microserviço TechSwat-Payment-Service (opcional — não altera o deploy existente)
# =============================================================================
# Provisiona:
#   • MongoDB (StatefulSet 1-replica + PVC EBS)  → svc-mongo-payment :27017
#   • ConfigMap + Secret específicos do payment
#   • Deployment (replicas: 1 — schedulers exigem leader único)
#   • Service LoadBalancer (entrada do webhook MercadoPago + DNS interno do monólito)
# Acionado quando var.enable_payment_service = true.

# -----------------------------------------------------------------------------
# MongoDB — StatefulSet com PVC EBS
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "mongo_payment_service_account" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-mongo-payment
  namespace: nstechswat
  labels:
    app: mongo-payment
spec:
  selector:
    app: mongo-payment
  ports:
    - protocol: TCP
      port: 27017
      targetPort: 27017
  clusterIP: None
YAML
}

resource "kubectl_manifest" "mongo_payment_statefulset" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.mongo_payment_service_account, kubectl_manifest.secrets_techswat_payment]
  yaml_body  = <<-YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo-payment
  namespace: nstechswat
spec:
  serviceName: svc-mongo-payment
  replicas: 1
  selector:
    matchLabels:
      app: mongo-payment
  template:
    metadata:
      labels:
        app: mongo-payment
    spec:
      containers:
        - name: mongo
          image: mongo:7.0
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat-payment
                  key: MONGO_ROOT_USERNAME
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: secrets-techswat-payment
                  key: MONGO_ROOT_PASSWORD
          volumeMounts:
            - name: data
              mountPath: /data/db
          readinessProbe:
            exec:
              command:
                - mongosh
                - --quiet
                - --eval
                - "db.adminCommand('ping')"
            initialDelaySeconds: 15
            periodSeconds: 10
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
            storage: ${var.payment_mongo_storage_size}
YAML
}

# -----------------------------------------------------------------------------
# Secret — credenciais de provider, AWS SQS e Mongo
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "secrets_techswat_payment" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: secrets-techswat-payment
  namespace: nstechswat
type: Opaque
stringData:
  MONGO_ROOT_USERNAME: ${var.payment_mongo_username}
  MONGO_ROOT_PASSWORD: ${var.payment_mongo_password}
  SPRING_DATA_MONGODB_URI: mongodb://${var.payment_mongo_username}:${var.payment_mongo_password}@svc-mongo-payment.nstechswat.svc.cluster.local:27017/${var.payment_mongo_db_name}?authSource=admin
  PAYMENTS_PROVIDERS_MERCADOPAGO_ACCESS_TOKEN: ${var.payment_mp_access_token}
  PAYMENTS_WEBHOOKS_MERCADOPAGO_SHARED_SECRET: ${var.payment_mp_webhook_secret}
  AWS_ACCESS_KEY_ID: ${var.payment_aws_access_key_id}
  AWS_SECRET_ACCESS_KEY: ${var.payment_aws_secret_access_key}
  AWS_SESSION_TOKEN: ${var.payment_aws_session_token}
YAML
}

# -----------------------------------------------------------------------------
# ConfigMap — envs não sensíveis
# -----------------------------------------------------------------------------

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
  SPRING_APPLICATION_NAME: techswat-payment-service
  SERVER_PORT: "8080"
  PAYMENTS_PROVIDERS_MERCADOPAGO_BASE_URL: https://api.mercadopago.com
  PAYMENTS_PROVIDERS_MERCADOPAGO_SANDBOX: "${var.payment_mp_sandbox}"
  PAYMENTS_WEBHOOKS_MERCADOPAGO_SIGNATURE_REQUIRED: "true"
  PAYMENTS_API_CREATE_HTTP_ENABLED: "true"
  PAYMENTS_BROKER_TRANSPORT: sqs
  PAYMENTS_BROKER_SQS_REGION: ${var.payment_aws_region}
  PAYMENTS_BROKER_SQS_QUEUE_URL: ${var.payment_sqs_outbound_queue_url}
  PAYMENTS_BROKER_SQS_INBOUND_ENABLED: "true"
  PAYMENTS_BROKER_SQS_INBOUND_QUEUE_URL: ${var.payment_sqs_inbound_queue_url}
  MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE: health,info,metrics
YAML
}

# -----------------------------------------------------------------------------
# Deployment
# -----------------------------------------------------------------------------

resource "kubectl_manifest" "deploy_techswat_payment" {
  count = var.enable_payment_service ? 1 : 0
  depends_on = [
    kubectl_manifest.configmap_techswat_payment,
    kubectl_manifest.secrets_techswat_payment,
    kubectl_manifest.mongo_payment_statefulset,
  ]
  wait_for_rollout = false
  yaml_body        = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-techswat-payment
  namespace: nstechswat
spec:
  replicas: 1
  strategy:
    type: Recreate
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
            - secretRef:
                name: secrets-techswat-payment
          startupProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            failureThreshold: 30
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 20
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 3
          resources:
            requests:
              cpu: "150m"
              memory: "384Mi"
            limits:
              cpu: "600m"
              memory: "768Mi"
YAML
}

# -----------------------------------------------------------------------------
# Service — LoadBalancer (entrada do webhook MercadoPago)
#   Também acessível internamente via DNS svc-techswat-payment.nstechswat.svc.cluster.local
# -----------------------------------------------------------------------------

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
  type: LoadBalancer
YAML
}

# -----------------------------------------------------------------------------
# Data source para obter o hostname do LoadBalancer do payment
# -----------------------------------------------------------------------------

resource "time_sleep" "wait_for_payment_lb" {
  count           = var.enable_payment_service ? 1 : 0
  depends_on      = [kubectl_manifest.service_techswat_payment]
  create_duration = "60s"
}

data "kubernetes_service_v1" "payment_lb" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [time_sleep.wait_for_payment_lb]
  metadata {
    name      = "svc-techswat-payment"
    namespace = "nstechswat"
  }
}
