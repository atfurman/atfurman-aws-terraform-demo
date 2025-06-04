provider "aws" {
    region  = "${aws_region}"
    use_fips_endpoint = true
    assume_role {
        # Note that aws_partition is parameterized- this is required to support both commercial and govcloud partitions
        role_arn = "arn:${aws_partition}:iam::${account_id}:role/${tf_deploy_role_name}"
    }
}

terraform {
    backend "s3" {
        bucket         = "${s3_tf_state_bucket_name}"
        key            = "tf-deploy"
        region         = "${aws_region}"
        use_lockfile   = true
        encrypt        = true
    }
}