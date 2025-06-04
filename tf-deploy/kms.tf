# Define a CMK for the web server
resource "aws_kms_key" "web_server_cmk" {
  description             = "CMK for demo web server"
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = {
    Name        = "${var.system_prefix}-web-server-cmk"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_key_policy" "web_server_cmk" {
  key_id = aws_kms_key.web_server_cmk.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:${var.aws_partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = resource.aws_iam_role.web_server_role.arn
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


# Define a CMK for S3 bucket encryption
resource "aws_kms_key" "s3_bucket_cmk" {
  description             = "CMK for demo S3 bucket encryption"
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = {
    Name        = "${var.system_prefix}-s3-bucket-cmk"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}

# Write policy for S3 bucket CMK granting access to the web server role (these are the same, but generally the access to data in S3 is going to need to be managed distinctly)
resource "aws_kms_key_policy" "s3_bucket_cmk" {
  key_id = aws_kms_key.s3_bucket_cmk.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:${var.aws_partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = resource.aws_iam_role.web_server_role.arn
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