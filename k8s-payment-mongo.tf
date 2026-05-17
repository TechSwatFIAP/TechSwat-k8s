# =============================================================================
# MongoDB no cluster (persistência do TechSwat-Payment-Service)
# =============================================================================

resource "kubectl_manifest" "deploy_payment_mongo" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-payment-mongo
  namespace: nstechswat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-mongo
  template:
    metadata:
      labels:
        app: payment-mongo
    spec:
      containers:
        - name: mongo
          image: mongo:6.0
          ports:
            - containerPort: 27017
          resources:
            requests:
              cpu: "50m"
              memory: "128Mi"
            limits:
              cpu: "300m"
              memory: "512Mi"
YAML
}

resource "kubectl_manifest" "service_payment_mongo" {
  count      = var.enable_payment_service ? 1 : 0
  depends_on = [kubectl_manifest.deploy_payment_mongo]
  yaml_body  = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: svc-payment-mongo
  namespace: nstechswat
spec:
  selector:
    app: payment-mongo
  ports:
    - protocol: TCP
      port: 27017
      targetPort: 27017
  type: ClusterIP
YAML
}
