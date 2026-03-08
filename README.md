# TechSwat-k8s

Módulo Terraform para infraestrutura Kubernetes (EKS) do projeto TechSwat.

## Recursos Criados

- **EKS Cluster**: Cluster Kubernetes gerenciado na AWS
- **EKS Node Group**: Grupo de nodes para o cluster
- **EKS Access Entry**: Configuração de acesso ao cluster
- **Namespace**: `nstechswat`
- **Secrets**: Credenciais do MySQL, Redis e JWT
- **ConfigMap**: Configurações da aplicação
- **Deployment**: Deploy da aplicação TechSwat
- **Service**: LoadBalancer para expor a aplicação
- **HPA**: Horizontal Pod Autoscaler

## Uso

```hcl
module "kubernetes" {
  source = "git::https://github.com/ORG/TechSwat-k8s.git?ref=main"

  project_name       = "techswat-terraform"
  subnet_ids         = aws_subnet.public[*].id
  security_group_ids = [aws_security_group.eks.id]
  voclabs_role_arn   = "arn:aws:iam::123456789:role/voclabs"
  cluster_role_arn   = data.aws_iam_role.cluster.arn
  node_role_arn      = data.aws_iam_role.node.arn
  
  mysql_endpoint     = module.database.mysql_endpoint
  mysql_port         = module.database.mysql_port
  redis_private_ip   = module.database.redis_private_ip
  
  techswat_image     = "bagatim/techswat:latest"
  jwt_secret         = var.jwt_secret
}
```

## Variáveis de Entrada

| Nome | Descrição | Tipo | Default |
|------|-----------|------|---------|
| `project_name` | Nome do projeto | `string` | `"techswat-terraform"` |
| `subnet_ids` | Lista de IDs das subnets | `list(string)` | - |
| `security_group_ids` | Lista de IDs dos SGs | `list(string)` | - |
| `voclabs_role_arn` | ARN do role voclabs | `string` | - |
| `cluster_role_arn` | ARN do role do cluster | `string` | - |
| `node_role_arn` | ARN do role dos nodes | `string` | - |
| `mysql_endpoint` | Endpoint do MySQL | `string` | - |
| `mysql_port` | Porta do MySQL | `string` | `"3306"` |
| `mysql_db_name` | Nome do banco | `string` | `"techswat_db"` |
| `redis_private_ip` | IP privado do Redis | `string` | - |
| `techswat_image` | Imagem Docker | `string` | `"bagatim/techswat:latest"` |
| `jwt_secret` | Segredo JWT | `string` | - |
| `mysql_root_password` | Senha MySQL | `string` | `"techswat"` |
| `redis_password` | Senha Redis | `string` | `"myRedis2025"` |
| `instance_type` | Tipo de instância | `string` | `"t3.micro"` |

## Outputs

| Nome | Descrição |
|------|-----------|
| `cluster_name` | Nome do cluster EKS |
| `cluster_endpoint` | Endpoint do cluster |
| `cluster_certificate_authority` | CA do cluster |
| `cluster_arn` | ARN do cluster |
| `node_group_name` | Nome do node group |
| `service_namespace` | Namespace do serviço |
| `service_name` | Nome do serviço |
