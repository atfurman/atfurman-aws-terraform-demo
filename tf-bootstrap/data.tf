# Get the current user info, as this user needs to be able to assume the role.
data "aws_caller_identity" "current" {}
data "aws_caller_identity" "account" {}
# Get the current AWS partition
data "aws_partition" "current" {}