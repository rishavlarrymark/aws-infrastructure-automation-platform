
variable "bucket_name" {
  description = "S3 bucket name."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
}

variable "enable_iam" {
  description = "Whether to create an S3 read-only IAM policy."
  type        = bool
  default     = false
}

variable "noncurrent_version_expiration_days" {
  description = "Days before old object versions expire."
  type        = number
  default     = 90
}