# IAM Trust Policy — WHO can assume this role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = [var.service_principal]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Role
resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# Permission Policy Document — WHAT the role can do
data "aws_iam_policy_document" "custom" {
  statement {
    effect    = "Allow"
    actions   = var.policy_actions
    resources = var.policy_resources
  }
}

# IAM Policy
resource "aws_iam_policy" "this" {
  name        = "${var.role_name}-policy"
  description = "Permissions for ${var.role_name}"
  policy      = data.aws_iam_policy_document.custom.json
  tags        = var.tags
}

# Attach Permissions Policy to Role
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

# IAM Instance Profile — Allows EC2 to use the role
resource "aws_iam_instance_profile" "this" {
  name = var.role_name
  role = aws_iam_role.this.name
  tags = var.tags
}
