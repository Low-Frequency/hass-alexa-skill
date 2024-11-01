data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = var.policy_document.effect

    principals {
      type        = var.policy_document.principals.type
      identifiers = var.policy_document.principals.identifiers
    }

    actions = var.policy_document.actions
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.name}Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    ManagedBy   = "Terraform"
    Description = var.description
  }
}

resource "aws_iam_role_policy" "policy" {
  name = "${var.name}Permissions"
  role = aws_iam_role.role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = var.policy.action
        Effect   = "${var.policy.effect}"
        Resource = "${var.policy.resource}"
      },
    ]
  })
}
