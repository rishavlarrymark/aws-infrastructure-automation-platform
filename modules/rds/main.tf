# 1. RDS DB SUBNET GROUP
# Defines private subnets across at least two Availability Zones.

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-subnet-group"
  description = "Private subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-group"
  })
}


# 2. RDS SECURITY GROUP
# Controls network access to the PostgreSQL database.

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}


# 3. RDS INGRESS RULE
# Allows PostgreSQL traffic only from authorized application security groups.

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = toset(var.application_security_group_ids)

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value

  description = "Allow PostgreSQL from application EC2"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
}


# 4. RDS POSTGRESQL DATABASE INSTANCE
# Provisions a private, encrypted PostgreSQL database with automated backups.

resource "aws_db_instance" "this" {
  # Database identification
  identifier = var.name

  # Database engine configuration
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database name and credentials
  db_name  = var.db_name
  username = var.username
  password = var.password

  # PostgreSQL listening port
  port = 5432

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Private network and security configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false

  # Automated backup configuration
  backup_retention_period = var.backup_retention_period

  # Maintenance and availability configuration
  auto_minor_version_upgrade = true
  multi_az                   = var.multi_az

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Final snapshot configuration
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier

  # Export database logs to CloudWatch
  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  # Apply eligible changes during the maintenance window
  apply_immediately = false

  # Apply common and resource-specific tags
  tags = merge(var.tags, {
    Name = var.name
  })

  # Require a final snapshot identifier unless snapshot creation is skipped
  lifecycle {
    precondition {
      condition = (
        var.skip_final_snapshot ||
        var.final_snapshot_identifier != null
      )

      error_message = "Provide a final snapshot identifier unless skip_final_snapshot is true."
    }
  }
}