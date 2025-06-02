# Versioned S3 bucket to store terraform state for the tf-deploy state
module "s3_tf_state" {
  source                           = "terraform-aws-modules/s3-bucket/aws"
  bucket                           = "${var.system_prefix}-${data.aws_caller_identity.account.id}-tf-state"
  force_destroy                    = false
  acl                              = "private"
  object_ownership                 = "BucketOwnerEnforced"
  restrict_public_buckets          = true
  block_public_acls                = true
  block_public_policy              = true
  attach_require_latest_tls_policy = true
  versioning = {
    enabled    = true
    mfa_delete = false # Not required for this demo
  }
  tags = {
    Name  = "${var.system_prefix}-tf-state"
    Stage = "tf-bootstrap"
  }
  # Enable server-side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.tf_state.id
      }
    }
  }
}