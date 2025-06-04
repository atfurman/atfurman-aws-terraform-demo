module "demo_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "${var.system_prefix}-vpc"
  cidr   = "10.0.0.0/16"
  # Define azs based on the region
  azs                           = data.aws_availability_zones.available.names
  private_subnets               = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
  public_subnets                = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  enable_nat_gateway            = false # This won't be used in this demo.check "
  enable_vpn_gateway            = false
  create_igw                    = true
  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true
  enable_dns_hostnames          = true
  # Default security group should allow no ingress or egress traffic
  default_security_group_name    = "${var.system_prefix}-default-sg"
  default_security_group_ingress = []
  default_security_group_egress  = []
  default_security_group_tags = {
    "Name"        = "${var.system_prefix}-default-sg"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_destination_type            = "cloud-watch-logs"
  create_vpc                           = true
  tags = {
    "Name"        = "${var.system_prefix}-vpc"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }

}

# Define least permission security groups for the web server and ALB
# ALB Security Group - allows public HTTPS/HTTP ingress
module "alb_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  name                = "${var.system_prefix}-alb-sg"
  vpc_id              = module.demo_vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
  tags = {
    "Name"        = "${var.system_prefix}-alb-sg"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}
# Web server Security Group - allows ALB sg ingress on 443
module "web_server_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "${var.system_prefix}-web-sg"
  vpc_id = module.demo_vpc.vpc_id
  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]
  egress_rules = ["all-all"]
  tags = {
    "Name"        = "${var.system_prefix}-web-sg"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}