
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