variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "system_prefix" {
  description = "The prefix for system resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.system_prefix))
    error_message = "The system_prefix must only contain lowercase letters, numbers, hyphens, and periods (S3 bucket name safe characters)."
  }
}

variable "aws_partition" {
  description = "The AWS partition (e.g., aws, aws-us-gov for GovCloud)"
  type        = string
  validation {
    condition     = can(regex("^(aws|aws-us-gov)$", var.aws_partition))
    error_message = "The aws_partition must be either 'aws' or 'aws-us-gov'."
  }
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "The account_id must be a valid 12-digit AWS account ID."
  }
}
variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0ae9f87d24d606be4" # 2025-05-30 Amazon Linux 2023 AMI (x86_64) - We'd typically be building a hardened STIG/FIPS image and launching from that, but for demo purposes we'll use a standard AMI.
  validation {
    condition     = can(regex("^ami-[a-z0-9]+$", var.ami_id))
    error_message = "The ami_id must be a valid AMI ID."
  }
}

variable "web_server_instance_type" {
  description = "The instance type for the web server"
  type        = string
  default     = "t3.small"
}