# =============================================================================
# TechSwat-k8s: Módulo Kubernetes (EKS + Manifests)
# =============================================================================

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------

resource "aws_eks_cluster" "cluster" {
  name = "eks-${var.project_name}"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.cluster_role_arn
  version  = "1.31"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# EKS Node Group
# -----------------------------------------------------------------------------

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "nodeg-${var.project_name}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  disk_size       = 20
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# EKS Access Entry
# -----------------------------------------------------------------------------

resource "aws_eks_access_entry" "access_entry" {
  cluster_name      = aws_eks_cluster.cluster.name
  principal_arn     = var.voclabs_role_arn
  kubernetes_groups = ["group-techswat"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "aws_entry_association" {
  cluster_name  = aws_eks_cluster.cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.voclabs_role_arn

  access_scope {
    type = "cluster"
  }
}
