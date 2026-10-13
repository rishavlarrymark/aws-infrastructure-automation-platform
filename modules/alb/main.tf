# resource "aws_lb" "this" {
#     name               = "engine-alb"
#     internal           = false
#     load_balancer_type = "application"

#     subnets = ["subnet-12345678"]

#     tags = var.tags
# }

# #Target Group

# resource "aws_lb_target_group" "this" {
#     name = "engine-target-group"
#     port = 80
#     protocol = "HTTP"
#     vpc_id   = "vpc-12345678"

#     health_check {
#         path = "/"
#         port = "80"
#     }
#     tags = var.tags
# }

# #Attach EC2 to target group

# resource "aws_lb_target_group_attachment" "this" {
#     target_group_arn = aws_lb_target_group.this.arn
#     target_id        = var.instance_id
#     port             = 80
# }

# #Listener

# resource "aws_lb_listener" "this" {
#     load_balancer_arn = aws_lb.this.arn
#     port              = 80
#     protocol          = "HTTP"

#     default_action {
#         type             = "forward"
#         target_group_arn = aws_lb_target_group.this.arn
#     }
# }