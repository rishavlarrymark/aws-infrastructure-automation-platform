
output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "igw_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}

output "web_security_group_id" {
  description = "Security group ID for public-facing resources."
  value       = aws_security_group.web_sg.id
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
