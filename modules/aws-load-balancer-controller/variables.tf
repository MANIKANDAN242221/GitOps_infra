variable "name_prefix" {
  description = "Prefix for the IAM policy name."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster the controller manages."
  type        = string
}

variable "vpc_id" {
  description = "VPC of the cluster. Passed explicitly so the controller doesn't need IMDS."
  type        = string
}

variable "aws_region" {
  description = "AWS region of the cluster."
  type        = string
}

variable "irsa_role_arn" {
  description = "IRSA role ARN for the controller's service account (from modules/iam irsa_roles)."
  type        = string
}

variable "namespace" {
  description = "Namespace the controller is installed into (must match the IRSA trust policy)."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Service account name (must match the IRSA trust policy)."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "chart_version" {
  description = "Version of the eks/aws-load-balancer-controller Helm chart. Keep iam_policy.json in sync with the matching app release."
  type        = string
  default     = "3.6.3"
}

variable "replica_count" {
  description = "Number of controller replicas."
  type        = number
  default     = 2
}

variable "extra_values" {
  description = "Extra YAML values passed to the chart (applied after the module's defaults)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
