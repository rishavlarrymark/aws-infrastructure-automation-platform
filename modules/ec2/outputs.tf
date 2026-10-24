
output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IPv4 address of the EC2 instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IPv4 address, if assigned."
  value       = aws_instance.this.public_ip
}

output "availability_zone" {
  description = "Availability Zone of the EC2 instance."
  value       = aws_instance.this.availability_zone
}

output "subnet_id" {
  description = "Subnet containing the EC2 instance."
  value       = aws_instance.this.subnet_id
}

output "security_group_id" {
  description = "ID of the security group attached to the EC2 instance."
  value       = aws_security_group.ec2_sg.id
}