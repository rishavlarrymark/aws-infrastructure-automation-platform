
variable "name" {
  description = "Name of the EC2 instance and security group."
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing private subnet."
  type        = string
}

variable "ec2_ami_id" {
  description = "Approved AMI ID in the selected AWS region."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-fA-F]+$", var.ec2_ami_id))
    error_message = "Provide a valid-looking AMI ID."
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "iam_instance_profile" {
  description = "Name of the EC2 IAM instance profile."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB allowed to access the application."
  type        = string
}

variable "application_port" {
  description = "Port on which the application listens."
  type        = number
  default     = 8000

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "ssh_allowed_cidrs" {
  description = "Approved IPv4 CIDRs allowed to connect through SSH."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.ssh_allowed_cidrs :
      can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"
    ])
    error_message = "SSH CIDRs must be valid IPv4 CIDRs and must not include 0.0.0.0/0."
  }
}

variable "key_name" {
  description = "Existing EC2 key pair name, required if SSH access is enabled."
  type        = string
  default     = null
  nullable    = true
}

variable "monitoring_enabled" {
  description = "Enable detailed CloudWatch EC2 monitoring."
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 10
}

variable "root_volume_type" {
  description = "EBS volume type for the root device."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.root_volume_type)
    error_message = "Root volume type must be gp3 or gp2."
  }
}

variable "ebs_kms_key_id" {
  description = "Optional KMS key ID or ARN for root EBS encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "user_data" {
  description = "Optional EC2 bootstrap script. Do not include secrets."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "tags" {
  description = "Common tags applied to EC2 resources."
  type        = map(string)
  default     = {}
}

variable "app_repo_url" {
  description = "Git repository URL containing the application."
  type        = string
}

variable "app_repo_branch" {
  description = "Git branch used for the initial application deployment."
  type        = string
  default     = "main"
}




# variable "app_subdirectory" {
#   description = "Relative path to the backend directory inside the repository."
#   type        = string
#   default     = "application/backend"
# }

# variable "app_module" {
#   description = "Python module and ASGI application object for Uvicorn."
#   type        = string
#   default     = "app.main:app"
# }
