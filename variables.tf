variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "techswat-terraform"
}

variable "subnet_ids" {
  description = "Lista de IDs das subnets para o EKS"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Lista de IDs dos security groups para o EKS"
  type        = list(string)
}

variable "voclabs_role_arn" {
  description = "ARN do role voclabs para acesso ao cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN do IAM role para o cluster EKS"
  type        = string
}

variable "node_role_arn" {
  description = "ARN do IAM role para os nodes do EKS"
  type        = string
}

variable "mysql_endpoint" {
  description = "Endpoint do RDS MySQL"
  type        = string
}

variable "mysql_port" {
  description = "Porta do MySQL"
  type        = string
  default     = "3306"
}

variable "mysql_db_name" {
  description = "Nome do banco de dados MySQL"
  type        = string
  default     = "techswat_db"
}

variable "redis_private_ip" {
  description = "IP privado do Redis"
  type        = string
}

variable "techswat_image" {
  description = "Imagem Docker da aplicação TechSwat"
  type        = string
  default     = "bagatim/techswat:latest"
}

variable "jwt_secret" {
  description = "Segredo para assinatura do JWT"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "Senha root do MySQL"
  type        = string
  sensitive   = true
  default     = "techswat"
}

variable "redis_password" {
  description = "Senha do Redis"
  type        = string
  sensitive   = true
  default     = "myRedis2025"
}

variable "instance_type" {
  description = "Tipo de instância para os nodes do EKS"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default = {
    Name        = "techswat"
    Environment = "Development"
  }
}

# -----------------------------------------------------------------------------
# TechSwat-Order-Service (opcional)
# -----------------------------------------------------------------------------

variable "enable_order_service" {
  description = "Quando true, aplica Deployment/Service/ConfigMap do TechSwat-Order-Service no mesmo namespace"
  type        = bool
  default     = false
}

variable "techswat_order_image" {
  description = "Imagem Docker do TechSwat-Order-Service"
  type        = string
  default     = "bagatim/techswat-order-service:latest"
}

variable "mysql_order_db_name" {
  description = "Nome do banco MySQL dedicado ao microserviço de ordens (deve existir no RDS)"
  type        = string
  default     = "techswat_os_db"
}

variable "order_messaging_transport" {
  description = "Transporte de mensagens do pod: off | rabbit (RabbitMQ em todos os ambientes)"
  type        = string
  default     = "rabbit"
}

variable "internal_order_api_key" {
  description = "Chave X-Internal-Api-Key compartilhada entre TechSwat e order-service (bridge HTTP)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "order_rabbitmq_host" {
  description = "Host RabbitMQ usado pelo pod (se transport=rabbit)"
  type        = string
  default     = "localhost"
}

variable "order_rabbitmq_port" {
  description = "Porta RabbitMQ para o pod"
  type        = string
  default     = "5672"
}

variable "order_rabbitmq_username" {
  type    = string
  default = "guest"
}

variable "order_rabbitmq_password" {
  type      = string
  default   = "guest"
  sensitive = true
}

# -----------------------------------------------------------------------------
# TechSwat-Stock-Service (opcional)
# -----------------------------------------------------------------------------

variable "enable_stock_service" {
  description = "Quando true, aplica Deployment/Service/ConfigMap do TechSwat-Stock-Service no mesmo namespace"
  type        = bool
  default     = true
}

variable "techswat_stock_image" {
  description = "Imagem Docker do TechSwat-Stock-Service"
  type        = string
  default     = "bagatim/techswat-stock-service:latest"
}

variable "mysql_stock_db_name" {
  description = "Nome do banco MySQL dedicado ao microserviço de estoque (deve existir no RDS)"
  type        = string
  default     = "stock_db"
}
