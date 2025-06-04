# Generate SSH key pair
resource "tls_private_key" "web_server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "web_server_key_pair" {
  key_name   = "${var.system_prefix}-web-key-pair"
  public_key = tls_private_key.web_server.public_key_openssh
  tags = {
    "Name"        = "${var.system_prefix}-web-key-pair"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}

# Define ec2 instance for the web server
module "web_server" {
  source                       = "github.com/Coalfire-CF/terraform-aws-ec2?depth=1&ref=v2.0.12" # Shallow clone the module
  name                         = "${var.system_prefix}-web-server"
  ami                          = var.ami_id
  ec2_instance_type            = var.web_server_instance_type
  vpc_id                       = module.demo_vpc.vpc_id
  instance_count               = 1
  subnet_ids                   = module.demo_vpc.public_subnets
  root_volume_size             = 20
  root_volume_type             = "gp3"
  volume_delete_on_termination = true
  ec2_key_pair                 = aws_key_pair.web_server_key_pair.key_name
  ebs_kms_key_arn              = aws_kms_key.web_server_cmk.arn
  global_tags = {
    "Name"        = "${var.system_prefix}-web-server"
    "Environment" = "Demo"
    "Role"        = "web-server"
    "ManagedBy"   = "Terraform"
  }
  iam_profile           = aws_iam_instance_profile.web_server_profile.name
  create_security_group = false
  associate_public_ip   = true
  additional_security_groups = [
    module.web_server_sg.security_group_id
  ]
  http_tokens                 = "required" # Enforce instance metadata service v2
  http_put_response_hop_limit = 1          # Limit the number of hops for instance metadata service requests
  instance_metadata_tags      = "enabled"  # Enable instance metadata tags
  target_group_arns           = [resource.aws_lb_target_group.web_server_target_group.arn]
}

# Define target group
resource "aws_lb_target_group" "web_server_target_group" {
  name     = "${var.system_prefix}-web-server-tg"
  vpc_id   = module.demo_vpc.vpc_id
  protocol = "HTTPS"
  port     = 443
  health_check {
    path                = "/"
    enabled             = true
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTPS"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    "Name"        = "${var.system_prefix}-web-server-tg"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}