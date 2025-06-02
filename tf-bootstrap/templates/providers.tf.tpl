provider "aws" {
    region  = "${var.aws_region}"
    assume_role {
        role_arn = "arn:aws:iam::${var.account_id}:role/${var.tf_deploy_role_name}"
    }
}

terraform {
    backend "s3" {
        bucket         = "${var.tf_state_bucket}"
        key            = "${var.tf_state_key}"
        region         = "${var.aws_region}"
        use_lockfile   = true
        encrypt        = true
    }
}