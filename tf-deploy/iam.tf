# Define IAM role and instance profile for the web server
resource "aws_iam_role" "web_server_role" {
  name = "${var.system_prefix}-web-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    "Name"        = "${var.system_prefix}-web-server-role",
    "Environment" = "Demo",
    "ManagedBy"   = "Terraform"
  }
}

# Attach AWS managed policy for SSM Core functionality
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.web_server_role.name
  policy_arn = "arn:${var.aws_partition}:iam::${var.aws_partition}:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy example
resource "aws_iam_policy" "custom_policy" {
  name        = "${var.system_prefix}-web-server-custom-policy"
  description = "Web server custom policy for SSM logging and S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:${var.aws_partition}:logs:${var.aws_region}:${var.account_id}:log-group:/aws/ssm/*",
          "arn:${var.aws_partition}:logs:${var.aws_region}:${var.account_id}:log-group:/aws/ssm/*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:${var.aws_partition}:s3:::${var.system_prefix}-${var.account_id}-web-server-bucket"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = "arn:${var.aws_partition}:s3:::${var.system_prefix}-${var.account_id}-web-server-bucket/*"
      }
    ]
  })

  tags = {
    "Name"        = "${var.system_prefix}-web-server-custom-policy"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}

# Attach the custom logging policy
resource "aws_iam_role_policy_attachment" "custom_policy" {
  role       = aws_iam_role.web_server_role.name
  policy_arn = aws_iam_policy.custom_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "web_server_profile" {
  name = "${var.system_prefix}-web-server-profile"
  role = aws_iam_role.web_server_role.name

  tags = {
    "Name"        = "${var.system_prefix}-web-server-profile"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}