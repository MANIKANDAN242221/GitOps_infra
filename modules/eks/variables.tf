variable "cluster_name" {
  description = "Name of the EKS cluster, used as a prefix for all resource names."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane and node group."
  type        = string
  default     = "1.34"
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID of the VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the control plane ENIs (usually public + private)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "node_subnet_ids" {
  description = "Subnets for the worker nodes (usually private). Defaults to subnet_ids when empty."
  type        = list(string)
  default     = []
}

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs. Must not overlap the VPC."
  type        = string
  default     = "172.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_ipv4_cidr, 0))
    error_message = "service_ipv4_cidr must be a valid IPv4 CIDR block."
  }
}

# -----------------------------------------------------------------------------
# API endpoint access
# -----------------------------------------------------------------------------
variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Expose the Kubernetes API endpoint inside the VPC."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_api_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the private API endpoint on 443 (e.g. the VPC CIDR)."
  type        = list(string)
  default     = []
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Give whoever creates the cluster admin. Set false and list every admin in cluster_admin_arns instead."
  type        = bool
  default     = true
}

variable "cluster_admin_arns" {
  description = "IAM role/user ARNs granted cluster admin via access entries. Must not include the creator when the flag above is true."
  type        = list(string)
  default     = []
}

variable "cluster_log_types" {
  description = "Control plane log types sent to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

# -----------------------------------------------------------------------------
# Node group
# -----------------------------------------------------------------------------
variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_ami_type" {
  description = "AMI type for the nodes."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_disk_size" {
  description = "Root volume size (GiB) for each node."
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Desired number of nodes (only used on create; ignored afterwards)."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 3

  validation {
    condition     = var.node_max_size >= 1
    error_message = "node_max_size must be at least 1."
  }
}

variable "node_ssh_key_name" {
  description = "EC2 key pair for SSH access to nodes. Leave empty to disable (use SSM instead)."
  type        = string
  default     = ""
}

variable "node_labels" {
  description = "Kubernetes labels applied to the nodes."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Add-ons (null = EKS default version for the cluster)
# -----------------------------------------------------------------------------
variable "vpc_cni_version" {
  description = "Version of the vpc-cni add-on."
  type        = string
  default     = null
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy add-on."
  type        = string
  default     = null
}

variable "coredns_version" {
  description = "Version of the coredns add-on."
  type        = string
  default     = null
}

variable "enable_ebs_csi_driver" {
  description = "Install the EBS CSI driver add-on (needed for PersistentVolumes on gp2/gp3)."
  type        = bool
  default     = true
}

variable "ebs_csi_version" {
  description = "Version of the aws-ebs-csi-driver add-on."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
