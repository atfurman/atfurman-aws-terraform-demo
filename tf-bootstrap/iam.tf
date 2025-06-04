# Define the IAM role for the tf-deploy stage.
resource "aws_iam_role" "tf_deploy" {
  name = "${var.system_prefix}-tf-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Attach managed policies to the tf_deploy role.
resource "aws_iam_role_policy_attachment" "tf_deploy_admin" {
  role       = aws_iam_role.tf_deploy.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}
