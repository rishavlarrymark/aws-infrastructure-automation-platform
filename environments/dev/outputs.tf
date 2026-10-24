# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the secure S3 bucket."
  value       = module.secure_s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the secure S3 bucket."
  value       = module.secure_s3.bucket_arn
}




# IAM Outputs

output "iam_role_name" {
  description = "Name of the IAM role for S3 read access."
  value       = module.iam_s3_read_role.role_name
}




# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "igw_id" {
  description = "ID of the Internet Gateway."
  value       = module.vpc.igw_id
}



# EC2 Outputs

output "ec2_instance_id" {
  description = "ID of the development EC2 instance."
  value       = module.ec2_engine.instance_id
}

output "ec2_private_ip" {
  description = "Private IPv4 address of the development EC2 instance."
  value       = module.ec2_engine.private_ip
}

output "ec2_security_group_id" {
  description = "ID of the security group attached to the EC2 instance."
  value       = module.ec2_engine.security_group_id
}
