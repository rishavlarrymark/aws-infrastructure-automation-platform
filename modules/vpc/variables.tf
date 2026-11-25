
variable "vpc_cidr_block" {
  description = "VPC CIDR block for the main VPC."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "Provide a valid IPv4 CIDR block."
  }
}

variable "name" {
  description = "Name prefix for VPC resources."
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones used for subnet distribution."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.10.1.0/24",
    "10.10.2.0/24"
  ]
}

variable "app_subnet_cidrs" {
  description = "Application subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.10.11.0/24",
    "10.10.12.0/24"
  ]
}

variable "db_subnet_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.10.21.0/24",
    "10.10.22.0/24"
  ]
}

variable "tags" {
  description = "Common tags applied to VPC resources."
  type        = map(string)
}