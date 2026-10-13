# resource "aws_security_group" "ec2_sg" {
#   name        = "engine-ec2-sg"
#   description = "Security group for compute engine"

#   ingress {
#     description = "Allow HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = var.tags
# }

# resource "aws_iam_instance_profile" "ec2_profile" {
#   name = "engine-ec2-profile"
#   role = var.iam_role_name
# }

# resource "aws_instance" "engine_instance" {
#   ami           = "ami-12345678"
#   instance_type = "t2.micro"

#   subnet_id = var.subnet_id

#   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

#   vpc_security_group_ids = [
#     aws_security_group.ec2_sg.id
#   ]

#   user_data = file("${path.module}/user_data.sh")

#   tags = merge(
#     var.tags,
#     {
#       Name = var.instance_name
#     }
#   )
# }