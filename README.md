# TechSwat-k8s

Modulo Terraform para provisionamento do cluster EKS na AWS.
Todo o ciclo de deploy e controlado pelo repositorio principal: [TechSwat](https://github.com/TechSwatFIAP/TechSwat).

## Arquitetura

```
         [ LoadBalancer ] <-- externo (entrada)
                |
  +-------------+---------------------------+
  |         EKS Cluster                     |  <- este repositorio
  |  +--------------------------------------+|
  |  |       Namespace: nstechswat          ||
  |  |                                      ||
  |  |  [ Deployment: TechSwat ]            ||
  |  |          |                           ||
  |  |       [ HPA ]  1 a 3 pods            ||
  |  |                                      ||
  |  |  [ Secrets ]   [ ConfigMap ]         ||
  |  +--------------------------------------+|
  +-----------------------------------------+
```

## Recursos Provisionados

- EKS Cluster (`eks-techswat-terraform`, Kubernetes 1.31)
- Node Group: 1 node `t3.micro`
- Namespace `nstechswat` com Deployment, Service (LoadBalancer) e HPA (1-3 pods)
- **Opcional** (`enable_order_service = true`): ConfigMap/Secret/Deployment/Service **ClusterIP** do **TechSwat-Order-Service** (imagem `techswat_order_image`, banco `mysql_order_db_name`, mensageria `order_messaging_transport`, `TECHSWAT_BASE_URL` para o bridge HTTP), sem alterar os recursos existentes quando o flag permanece `false` (padrão).

## Deploy

Executado automaticamente via CI/CD do repositorio principal TechSwat.
Para execucao manual:

```bash
terraform init
terraform apply -auto-approve

aws eks update-kubeconfig --name eks-techswat-terraform --region us-east-1
kubectl get pods -n nstechswat
```
