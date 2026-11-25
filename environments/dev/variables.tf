# VPC NETWORK CONFIGURATION

variable "vpc_name" {
  description = "Name prefix for the VPC infrastructure."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "aws_region" {
  description = "AWS region where development infrastructure is deployed."
  type        = string
  default     = "ap-south-1"
}

variable "availability_zones" {
  description = "Availability Zones for the VPC subnets."
  type        = list(string)
}




# IAM ROLE CONFIGURATION

variable "iam_role_name" {
  description = "IAM role name for the EC2 application."
  type        = string
  default     = "task-management-ec2-role"
}

variable "iam_service_principal" {
  description = "AWS service allowed to assume the IAM role."
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "iam_policy_actions" {
  description = "IAM permissions required by the EC2 application."
  type        = list(string)
}




# EC2 COMPUTE & CONTAINER CONFIGURATION
variable "ec2_name" {
  description = "Name of the EC2 instance and its security group in the development environment."
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group ID of the Application Load Balancer."
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing private subnet."
  type        = string
}

variable "ec2_ami_id" {
  description = "Approved AMI ID for the development region."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-fA-F]+$", var.ec2_ami_id))
    error_message = "Provide a valid-looking EC2 AMI ID."
  }
}

variable "ec2_instance_type" {
  description = "EC2 instance type for development."
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidrs" {
  description = "Approved IPv4 CIDRs allowed to access EC2 through SSH."
  type        = set(string)
  default     = []
}

variable "key_name" {
  description = "Existing EC2 key pair name, if SSH access is enabled."
  type        = string
  default     = null
  nullable    = true
}

variable "monitoring_enabled" {
  description = "Enable detailed EC2 CloudWatch monitoring."
  type        = bool
  default     = false
}
variable "root_volume_size" {
  description = "EC2 root EBS volume size in GiB."
  type        = number
  default     = 10
}

variable "root_volume_type" {
  description = "EC2 root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "ebs_kms_key_id" {
  description = "Optional KMS key ID or ARN for EBS encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address with EC2."
  type        = bool
  default     = false
}

variable "ecr_registry" {
  description = "Amazon ECR registry URL."
  type        = string

  validation {
    condition     = length(trimspace(var.ecr_registry)) > 0
    error_message = "The ECR registry URL must not be empty."
  }
}

variable "image_name" {
  description = "Docker application image repository name."
  type        = string
  default     = "task-management-api"
}

variable "image_tag" {
  description = "Docker application image tag to deploy."
  type        = string
  default     = "v1"
}

variable "application_port" {
  description = "Host port exposed for the application."
  type        = number
  default     = 8000

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}




# RDS DATABASE CONFIGURATION

variable "rds_name" {
  description = "Unique identifier for the production RDS database."
  type        = string
}

variable "rds_username" {
  description = "Master username for production database authentication."
  type        = string
}

variable "rds_master_password" {
  description = "Master password for the production RDS database."
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  description = "Approved PostgreSQL engine version for production."
  type        = string
}

variable "rds_instance_class" {
  description = "Compute capacity of the production RDS instance."
  type        = string
}

variable "rds_allocated_storage" {
  description = "Initial production database storage in GiB."
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "Maximum production database storage in GiB."
  type        = number
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain production database backups."
  type        = number
  default     = 35
}




# S3 STORAGE CONFIGURATION
variable "s3_noncurrent_version_expiration_days" {
  description = "Days before noncurrent S3 object versions expire."
  type        = number
  default     = 90
}