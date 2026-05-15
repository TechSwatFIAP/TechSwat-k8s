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

variable "payment_service_image" {
  description = "Imagem Docker do microsserviço Payment-Service"
  type        = string
}

variable "mp_access_token" {
  description = "Access token do Mercado Pago (consumido pelo Payment-Service)"
  type        = string
  sensitive   = true
}

variable "mp_webhook_shared_secret" {
  description = "Shared secret para validar webhooks do Mercado Pago"
  type        = string
  sensitive   = true
}
