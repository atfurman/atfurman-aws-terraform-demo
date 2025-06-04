# KMS key used to encrypt tfstate s3 bucket
resource "aws_kms_key" "tf_state" {
  description             = "KMS key for encrypting Terraform state S3 bucket for tf-deploy stage"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = {
    Name  = "${var.system_prefix}-tf-state-kms-key"
    Stage = "tf-bootstrap"
  }
}

resource "aws_kms_key_policy" "tf_state" {
  key_id = aws_kms_key.tf_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Allow the current user full management
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      // Allow tf_deploy role encrypt/decrypt
      {
        Effect = "Allow"
        Principal = {
          AWS = resource.aws_iam_role.tf_deploy.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
