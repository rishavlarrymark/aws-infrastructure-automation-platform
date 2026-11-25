variable "name" {
  description = "Name identifier for the RDS database."
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the RDS DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs are required."
  }
}

variable "application_security_group_ids" {
  description = "Application security groups permitted to access PostgreSQL."
  type        = list(string)

  validation {
    condition     = length(var.application_security_group_ids) > 0
    error_message = "At least one application security group ID is required."
  }
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "taskmanagement"
}

variable "username" {
  description = "RDS master username."
  type        = string
}

variable "password" {
  description = "RDS master password."
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Supported PostgreSQL engine version."
  type        = string
}

variable "instance_class" {
  description = "RDS database instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial database storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled database storage in GiB."
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ database."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protect the database against accidental deletion."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the database."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for the final snapshot when deleting the database."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Common tags passed from the environment root."
  type        = map(string)
  default     = {}
}