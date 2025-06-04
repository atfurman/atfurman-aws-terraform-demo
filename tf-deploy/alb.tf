# Define certificate for the ALB. Since it is a demo environment, we will use a self-signed certificate.

# Generate self-signed certificate for demo
resource "tls_private_key" "alb_cert" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "alb_cert" {
  private_key_pem = tls_private_key.alb_cert.private_key_pem

  subject {
    common_name = "${var.system_prefix}-demo.local"
  }

  validity_period_hours = 8760 # 1 year 

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Store certs securely in SSM
resource "aws_ssm_parameter" "nginx_cert" {
  name  = "/demo/${var.system_prefix}/nginx/certificate"
  type  = "SecureString"
  value = tls_self_signed_cert.alb_cert.cert_pem

  tags = {
    "Name" = "${var.system_prefix}-nginx-cert"
  }
}

resource "aws_ssm_parameter" "nginx_key" {
  name  = "/demo/${var.system_prefix}/nginx/private_key"
  type  = "SecureString"
  value = tls_private_key.alb_cert.private_key_pem

  tags = {
    "Name" = "${var.system_prefix}-nginx-key"
  }
}

# Upload self-signed cert to ACM
resource "aws_acm_certificate" "alb" {
  private_key      = tls_private_key.alb_cert.private_key_pem
  certificate_body = tls_self_signed_cert.alb_cert.cert_pem

  tags = {
    "Name"        = "${var.system_prefix}-alb-cert"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}

# Define ALB for the web server
module "alb" {
  source                           = "terraform-aws-modules/alb/aws"
  name                             = "${var.system_prefix}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [module.alb_sg.security_group_id]
  create_security_group            = false
  subnets                          = module.demo_vpc.public_subnets
  enable_deletion_protection       = false
  idle_timeout                     = 60
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  tags = {
    "Name"        = "${var.system_prefix}-alb"
    "Environment" = "Demo"
    "ManagedBy"   = "Terraform"
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = module.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-3-FIPS-2023-04" # FIPS policy
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_target_group.arn
  }
}