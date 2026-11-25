
output "db_instance_id" {
  description = "Unique identifier of the RDS database instance for resource management and referencing."
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "DNS hostname used by application resources to establish a connection to the RDS database."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "TCP port on which the PostgreSQL database accepts incoming connections."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial PostgreSQL database created within the RDS instance."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master username used to authenticate with the RDS database."
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_security_group_id" {
  description = "ID of the RDS security group used to control inbound database traffic."
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group that defines the subnets available to the RDS instance."
  value       = aws_db_subnet_group.this.name
}

output "db_resource_id" {
  description = "AWS-generated immutable resource identifier of the RDS database instance."
  value       = aws_db_instance.this.resource_id
}
