provider "aws" {
  region = var.aws_region
  use_fips_endpoint = true
}