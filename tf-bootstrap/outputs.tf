# Define outputs for the bootstrap stage
output "s3_tf_state_bucket_name" {
  description = "The name of the S3 bucket used for Terraform state in the tf-deploy stage"
  value       = module.s3_tf_state.bucket
}

# Write providers file for the tf-deploy stage
output "tf_deploy_providers_file" {
  description = "The content of the providers file for the tf-deploy stage"
  value       = templatefile("${path.module}/templates/providers.tf.tpl", {
    aws_region = var.aws_region
    system_prefix = var.system_prefix
  })
}


