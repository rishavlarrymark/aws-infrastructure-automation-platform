# ===================
# CURRENT AWS REGION
# ===================

data "aws_region" "current" {}

# ===================
# VPC CONFIGURATION
# ===================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}


# ======================
# SUBNET CONFIGURATION
# ======================

# PUBLIC SUBNETS

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Type = "public"
    Tier = "public"
  })
}


# PRIVATE APPLICATION SUBNETS

resource "aws_subnet" "application" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 11)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-application-${count.index + 1}"
    Type = "application"
    Tier = "application"
  })
}


# PRIVATE DATABASE SUBNETS

resource "aws_subnet" "database" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 21)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name}-database-${count.index + 1}"
    Type = "database"
    Tier = "database"
  })
}


# ===============================
# INTERNET GATEWAY CONFIGURATION
# ===============================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}


# ===========================
# NAT GATEWAY CONFIGURATION
# ===========================

# NAT GATEWAY ELASTIC IP

resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}


# NAT GATEWAY

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.main,
    aws_route.public_internet,
    aws_route_table_association.public
  ]

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}


# ===========================
# ROUTE TABLE CONFIGURATION
# ===========================
# Creates separate routing tables for public, application, and database subnets.

# PUBLIC ROUTE TABLE

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
    Type = "public"
  })
}


# PRIVATE APPLICATION ROUTE TABLE

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-application-rt"
    Type = "application"
  })
}


# PRIVATE DATABASE ROUTE TABLE (LOCAL ROUTE ONLY)

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-database-rt"
    Type = "database"
  })
}


# =====================
# ROUTE CONFIGURATION
# =====================
# Adds routing rules to route tables to control where network traffic is forwarded.

# PUBLIC INTERNET ROUTE

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


# PRIVATE APPLICATION INTERNET ROUTE THROUGH NAT

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.application.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}


# ======================================
# ROUTE TABLE ASSOCIATION CONFIGURATION
# ======================================

# ASSOCIATE PUBLIC SUBNETS WITH THE PUBLIC ROUTE TABLE

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ASSOCIATE PRIVATE APPLICATION SUBNETS WITH THE APPLICATION ROUTE TABLE

resource "aws_route_table_association" "application" {
  count = length(aws_subnet.application)

  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.application.id
}


# ASSOCIATE PRIVATE DATABASE SUBNETS WITH THE DATABASE ROUTE TABLE

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}


# =============================
# SECURITY GROUP CONFIGURATION
# =============================

# Use this for public ALB HTTP/HTTPS-facing resources only.

resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "Allow public HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Allow traffic to application instances"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-alb-sg"
  })
}


# ==================================================
# NETWORK ACCESS CONTROL LIST (NACL) CONFIGURATION
# ==================================================

# ===========================
# PUBLIC NACL CONFIGURATION
# ===========================

# PUBLIC NACL

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-nacl"
  })
}


# ==========================
# PUBLIC NACL INBOUND RULES
# ==========================

# HTTP INBOUND RULE

resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# HTTPS INBOUND RULE

resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# EPHEMERAL PORT INBOUND RULE

resource "aws_network_acl_rule" "public_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ============================
# PUBLIC NACL OUTBOUND RULES
# ============================

# ALB TO APPLICATION SUBNETS

resource "aws_network_acl_rule" "public_out_application" {
  count = length(var.app_subnet_cidrs)

  network_acl_id = aws_network_acl.public.id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_subnet_cidrs[count.index]
  from_port      = 8000
  to_port        = 8000
}

# NAT GATEWAY OUTBOUND HTTPS

resource "aws_network_acl_rule" "public_out_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# EPHEMERAL PORT OUTBOUND RULE

resource "aws_network_acl_rule" "public_out_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# =======================================
# PUBLIC NACL ASSOCIATION CONFIGURATION
# =======================================

# PUBLIC SUBNET NACL ASSOCIATIONS

resource "aws_network_acl_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  network_acl_id = aws_network_acl.public.id
}


# ===============================
# APPLICATION NACL CONFIGURATION
# ===============================

# APPLICATION NACL

resource "aws_network_acl" "application" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-application-nacl"
  })
}

# ===============================
# APPLICATION NACL INBOUND RULES
# ===============================

# ALLOW ALB TRAFFIC TO FASTAPI APPLICATION ON PORT 8000

resource "aws_network_acl_rule" "application_in_alb" {
  count = length(var.public_subnet_cidrs)

  network_acl_id = aws_network_acl.application.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = 8000
  to_port        = 8000
}

# ALLOW EPHEMERAL RETURN TRAFFIC FROM DATABASE AND EXTERNAL SERVICES

resource "aws_network_acl_rule" "application_in_ephemeral" {
  network_acl_id = aws_network_acl.application.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ================================
# APPLICATION NACL OUTBOUND RULES
# ================================

# ALLOW POSTGRESQL TRAFFIC TO DATABASE SUBNETS

resource "aws_network_acl_rule" "application_out_database" {
  count = length(var.db_subnet_cidrs)

  network_acl_id = aws_network_acl.application.id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_subnet_cidrs[count.index]
  from_port      = 5432
  to_port        = 5432
}

# ALLOW OUTBOUND HTTPS THROUGH NAT GATEWAY

resource "aws_network_acl_rule" "application_out_https" {
  network_acl_id = aws_network_acl.application.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# ALLOW EPHEMERAL RETURN TRAFFIC TO PUBLIC SUBNETS

resource "aws_network_acl_rule" "application_out_ephemeral" {
  count = length(var.public_subnet_cidrs)

  network_acl_id = aws_network_acl.application.id
  rule_number    = 120 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

# ==============================
# APPLICATION NACL ASSOCIATIONS
# ==============================

# PRIVATE APPLICATION-SUBNET NACL ASSOCIATIONS

resource "aws_network_acl_association" "application" {
  count = length(aws_subnet.application)

  subnet_id      = aws_subnet.application[count.index].id
  network_acl_id = aws_network_acl.application.id
}

# =============================
# DATABASE NACL CONFIGURATION
# =============================

# DATABASE NACL

resource "aws_network_acl" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-database-nacl"
  })
}

# ============================
# DATABASE NACL INBOUND RULES
# ============================

# ALLOW POSTGRESQL TRAFFIC FROM APPLICATION SUBNETS

resource "aws_network_acl_rule" "database_in_application" {
  count = length(var.app_subnet_cidrs)

  network_acl_id = aws_network_acl.database.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_subnet_cidrs[count.index]
  from_port      = 5432
  to_port        = 5432
}

# ============================
# DATABASE NACL OUTBOUND RULES
# ============================

# ALLOW EPHEMERAL RETURN TRAFFIC TO APPLICATION SUBNETS

resource "aws_network_acl_rule" "database_out_application" {
  count = length(var.app_subnet_cidrs)

  network_acl_id = aws_network_acl.database.id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

# ============================
# DATABASE NACL ASSOCIATIONS
# ============================

# PRIVATE DATABASE-SUBNET NACL ASSOCIATIONS

resource "aws_network_acl_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  network_acl_id = aws_network_acl.database.id
}


# ============================
# VPC ENDPOINT CONFIGURATION
# ============================

# S3 GATEWAY VPC ENDPOINT

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.application.id]

  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}