variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "system_prefix" {
  description = "The prefix for system resources"
  type        = string
  default     = "aws-terraform-demo"
  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.system_prefix))
    error_message = "The system_prefix must only contain lowercase letters, numbers, hyphens, and periods (S3 bucket name safe characters)."
  }
}