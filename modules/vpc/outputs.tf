
output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets across the configured Availability Zones."
  value       = aws_subnet.public[*].id
}

output "application_subnet_ids" {
  description = "IDs of isolated private application subnets across the configured Availability Zones."
  value       = aws_subnet.application[*].id
}

output "database_subnet_ids" {
  description = "IDs of isolated private database subnets across the configured Availability Zones."
  value       = aws_subnet.database[*].id
}

output "igw_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}

output "alb_security_group_id" {
  description = "Security group ID for public-facing resources."
  value       = aws_security_group.alb_sg.id
}

output "public_subnet_az_mapping" {
  description = "Mapping of public subnet IDs to Availability Zones."
  value = [
    for subnet in aws_subnet.public : {
      subnet_id = subnet.id
      az        = subnet.availability_zone
    }
  ]
}