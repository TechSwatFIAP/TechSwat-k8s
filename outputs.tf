output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_certificate_authority" {
  description = "Certificate authority do cluster EKS"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.cluster.arn
}

output "node_group_name" {
  description = "Nome do node group"
  value       = aws_eks_node_group.node_group.node_group_name
}

output "service_namespace" {
  description = "Namespace do serviço TechSwat"
  value       = "nstechswat"
}

output "service_name" {
  description = "Nome do serviço TechSwat"
  value       = "svc-techswat"
}

output "load_balancer_hostname" {
  description = "Hostname do LoadBalancer do serviço TechSwat"
  value       = try(data.kubernetes_service_v1.techswat_lb.status[0].load_balancer[0].ingress[0].hostname, "aguardando...")
}
