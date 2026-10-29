#S3 Storage
# Provision secure S3 bucket for development

module "secure_s3" {
  source      = "../../modules/s3"
  bucket_name = "engine-dev-secure-bucket"
  tags        = local.common_tags
  enable_iam  = false
}






# EC2 Compute Layer
# Launch development compute instance

module "ec2_engine" {
  source = "../../modules/ec2"

  # Naming and networking
  name      = var.name
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  # Compute
  ec2_ami_id        = var.ec2_ami_id
  ec2_instance_type = var.ec2_instance_type

  # Existing IAM instance profile
  iam_instance_profile = var.iam_instance_profile

  # Application access
  alb_security_group_id = var.alb_security_group_id
  application_port      = var.application_port

  # Security
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  key_name          = var.key_name

  # Monitoring and storage
  monitoring_enabled          = var.monitoring_enabled
  root_volume_size            = var.root_volume_size
  ebs_kms_key_id              = var.ebs_kms_key_id
  associate_public_ip_address = false

  # Bootstrap
  user_data = templatefile(
    "${path.root}/../../ec2/user_data.sh",
    {
      aws_region       = var.aws_region
      ecr_registry     = var.ecr_registry
      image_name       = var.image_name
      image_tag        = var.image_tag
      application_port = var.application_port
    }
  )

  tags = local.common_tags
}




#Load balancer (Traffic Control Layer)
#Routes traffic to EC2 instances

module "alb" {
  source = "../../modules/alb"

  name              = "task-management-alb"
  target_group_name = "task-management-tg"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.vpc.web_security_group_id
  instance_id           = module.ec2.instance_id
  application_port      = 8000

  tags = local.common_tags
}




# VPC (Network Foundation Layer - Dev)
# Creates isolated network with multi-AZ subnets

module "vpc" {
  source = "../../modules/vpc"

  name               = var.name
  vpc_cidr_block     = var.vpc_cidr_block
  availability_zones = var.availability_zones

  # Cost allocation and resource ownership
  tags = local.common_tags
}
