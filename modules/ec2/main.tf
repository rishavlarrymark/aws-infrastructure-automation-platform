# EC2 Security Group

resource "aws_security_group" "ec2_sg" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-sg"
    ManagedBy = "Terraform"
  })
}

# Allow HTTP traffic only from the Application Load Balancer.

resource "aws_vpc_security_group_ingress_rule" "http_from_alb" {
  count = var.alb_security_group_id != null ? 1 : 0

  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = var.alb_security_group_id

  description = "HTTP from the Application Load Balancer"
  ip_protocol = "tcp"
  from_port   = var.application_port
  to_port     = var.application_port
}

# Allow outbound traffic for updates, AWS APIs, and application dependencies.

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.ec2_sg.id

  description = "Outbound IPv4 traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# EC2 Instance

resource "aws_instance" "this" {
  ami           = var.ec2_ami_id
  instance_type = var.ec2_instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile = var.iam_instance_profile
  key_name             = var.key_name

  associate_public_ip_address = false
  monitoring                  = var.monitoring_enabled

  user_data                   = var.user_data
  user_data_replace_on_change = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    kms_key_id            = var.ebs_kms_key_id
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.name}-root-volume"
    })
  }

  tags = merge(var.tags, {
    Name      = var.name
    ManagedBy = "Terraform"
  })

# Application deployment configuration.
# The backend path and ASGI entry point match the repository structure.
# Update these values if the application layout changes.

user_data = templatefile("${path.module}/../../application/startup.sh", {
  app_repo_url        = var.app_repo_url
  app_repo_branch     = var.app_repo_branch
})


  lifecycle {
    precondition {
      condition = (
        length(var.ssh_allowed_cidrs) == 0 ||
        try(length(trimspace(var.key_name)) > 0, false)
      )

      error_message = "A non-empty key pair name is required when SSH access is enabled."
    }
  }
}

# Optional SSH access from explicitly approved IPv4 CIDRs.

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = var.ssh_allowed_cidrs

  security_group_id = aws_security_group.ec2_sg.id

  description = "Restricted SSH administration"
  cidr_ipv4   = each.value
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}