variable "vpc_name" {
  description = "Name of the VPC, used as a prefix for all resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread the subnets across."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "At least one availability zone is required."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets (one per AZ)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) > 0
    error_message = "At least one public subnet is required (the NAT gateway lives in the first one)."
  }
}

variable "private_subnets" {
  description = "CIDR blocks for the private subnets (one per AZ)."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private subnets can reach the internet."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name. When set, subnets are tagged for EKS load balancer discovery."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
