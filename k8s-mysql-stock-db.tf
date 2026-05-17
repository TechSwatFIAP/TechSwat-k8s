# =============================================================================
# Cria o banco stock_db no RDS (quando o Stock-Service está habilitado)
# =============================================================================

resource "kubectl_manifest" "job_mysql_stock_db" {
  count      = var.enable_stock_service ? 1 : 0
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = <<-YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: mysql-init-stock-db
  namespace: nstechswat
spec:
  ttlSecondsAfterFinished: 600
  backoffLimit: 5
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: mysql-init
          image: mysql:8.0
          command:
            - sh
            - -c
            - |
              mysql -h "${var.mysql_endpoint}" -P "${var.mysql_port}" -uroot -p"${var.mysql_root_password}" \
                -e "CREATE DATABASE IF NOT EXISTS ${var.mysql_stock_db_name};"
YAML
}
