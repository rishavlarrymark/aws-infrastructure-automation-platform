
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
output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "read_only_policy_arn" {
  description = "IAM read-only policy ARN if enabled."
  value       = var.enable_iam ? aws_iam_policy.s3_read_only[0].arn : null
}