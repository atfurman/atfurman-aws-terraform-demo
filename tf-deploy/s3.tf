# Define an S3 bucket for the web server
module "s3_web_server" {
  source                           = "terraform-aws-modules/s3-bucket/aws"
  bucket                           = "${var.system_prefix}-${var.account_id}-web-server-bucket"
  force_destroy                    = true
  object_ownership                 = "BucketOwnerEnforced"
  restrict_public_buckets          = true
  block_public_acls                = true
  block_public_policy              = true
  attach_require_latest_tls_policy = true
  versioning = {
    enabled    = true
    mfa_delete = false # Not required for this demo
  }
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.web_server_role.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:${var.aws_partition}:s3:::${var.system_prefix}-${var.account_id}-web-server-bucket"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.web_server_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = "arn:${var.aws_partition}:s3:::${var.system_prefix}-${var.account_id}-web-server-bucket/*"
      }
    ]
  })
  
  tags = {
    Name        = "${var.system_prefix}-web-server"
    Environment = "Demo"
    Stage       = "tf-deploy"
  }
  
  # Enable server-side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_bucket_cmk.id
      }
    }
  }
}