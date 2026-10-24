
variable "cidr_block" {
  description = "VPC CIDR block."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
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

variable "tags" {
  description = "Common tags applied to VPC resources."
  type        = map(string)
}
