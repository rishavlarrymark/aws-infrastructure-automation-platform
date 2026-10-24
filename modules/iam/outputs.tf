output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "Attached IAM policy ARN"
  value       = aws_iam_policy.this.arn
}

output "instance_profile_name" {
  description = "IAM Intance profile name for EC2"
  value       = aws_iam_instance_profile.this.name
}