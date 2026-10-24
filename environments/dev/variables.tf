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

variable "app_repo_url" {
  description = "Git repository URL containing the application."
  type        = string

  validation {
    condition     = length(trimspace(var.app_repo_url)) > 0
    error_message = "The application repository URL must not be empty."
  }
}

variable "app_repo_branch" {
  description = "Application branch to deploy."
  type        = string
  default     = "main"
}

variable "app_subdirectory" {
  description = "Relative path to the backend application."
  type        = string
  default     = "application/backend"
}

variable "app_module" {
  description = "Python module and ASGI application object."
  type        = string
  default     = "app.main:app"
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