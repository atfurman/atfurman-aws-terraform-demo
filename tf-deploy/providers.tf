provider "aws" {
  region            = "us-east-2"
  use_fips_endpoint = true
  assume_role {
    # Note that aws_partition is parameterized- this is required to support both commercial and govcloud partitions
    role_arn = "arn:aws:iam::657239337823:role/aws-terraform-demo-tf-deploy"
  }
}

terraform {
  backend "s3" {
    bucket       = "aws-terraform-demo-657239337823-tf-state"
    key          = "tf-deploy"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}