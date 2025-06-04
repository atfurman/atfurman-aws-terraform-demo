# Define tfvars to be passed to the tf-deploy stage
locals {
  tfvars = {
    aws_region = var.aws_region
    aws_partition = data.aws_partition.current.partition
    account_id = data.aws_caller_identity.account.id
    system_prefix = var.system_prefix
  }
}

# Write providers file for the tf-deploy stage
resource "local_file" "tf_deploy_providers_file" {
  file_permission = "0644"
  content  = templatefile("${path.module}/templates/providers.tf.tpl", {
    aws_region = var.aws_region
    aws_partition = data.aws_partition.current.partition
    account_id = data.aws_caller_identity.account.id
    tf_deploy_role_name = resource.aws_iam_role.tf_deploy.name
    s3_tf_state_bucket_name = module.s3_tf_state.s3_bucket_id
  })
  filename = "../tf-deploy/providers.tf"
}

# Write tfvars file for the tf-deploy stage
resource "local_file" "tfvars" {
  file_permission = "0644"
  content = jsonencode(local.tfvars)
  filename = "../tf-deploy/tf-bootstrap.auto.tfvars.json"
}