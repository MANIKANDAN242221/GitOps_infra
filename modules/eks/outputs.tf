output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.main.arn
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = aws_eks_cluster.main.version
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes API server."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for the cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "ID of the additional cluster security group created by this module."
  value       = aws_security_group.cluster.id
}

output "cluster_primary_security_group_id" {
  description = "ID of the EKS-managed cluster security group (attached to nodes)."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "ARN of the cluster IAM role."
  value       = aws_iam_role.cluster.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider, for IRSA trust policies."
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_issuer" {
  description = "OIDC issuer host/path without https://, for IRSA condition keys."
  value       = local.oidc_issuer
}

output "node_group_name" {
  description = "Name of the managed node group."
  value       = aws_eks_node_group.main.node_group_name
}

output "node_iam_role_arn" {
  description = "ARN of the node IAM role."
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "Name of the node IAM role."
  value       = aws_iam_role.node.name
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IAM role (null when disabled)."
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
}
