# IAM Security

variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "" {
  description = "IAM role name"
  type        = string
}


# EC2 Compute Configuration

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

variable "aws_region" {
  description = "AWS region containing the ECR repository."
  type        = string
  default     = "ap-south-1"
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




# VPC Network

variable "name" {
  description = "Name prefix for the VPC infrastructure."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones for the VPC subnets."
  type        = list(string)
}