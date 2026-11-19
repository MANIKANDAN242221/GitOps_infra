output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to add this cluster to your kubeconfig."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "ecr_repository_urls" {
  description = "Map of repository name to URL."
  value       = module.ecr.repository_urls
}

output "github_actions_role_arn" {
  description = "Role the app repos' workflows assume to push images (set as the AWS_ROLE_ARN variable there)."
  value       = module.iam.github_actions_role_arn
}

output "argocd_admin_password_command" {
  description = "Command to read the initial Argo CD admin password."
  value       = module.argocd.initial_admin_password_command
}

output "grafana_port_forward_command" {
  description = "Command to reach Grafana on http://localhost:3000."
  value       = module.monitoring.grafana_port_forward_command
}

output "grafana_admin_password" {
  description = "Grafana admin password (terraform output -raw grafana_admin_password)."
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}

output "aws_load_balancer_controller_role_arn" {
  description = "IRSA role used by the AWS Load Balancer Controller."
  value       = module.iam.irsa_role_arns["aws-load-balancer-controller"]
}

output "ui_urls_command" {
  description = "Command that prints the Argo CD, Grafana and Prometheus load balancer URLs (when expose_uis = true)."
  value       = <<-EOT
    echo "Argo CD:    http://$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
    echo "Grafana:    http://$(kubectl -n monitoring get svc kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
    echo "Prometheus: http://$(kubectl -n monitoring get svc kube-prometheus-stack-prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):9090"
  EOT
}
