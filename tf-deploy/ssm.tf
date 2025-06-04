# Put the server into FIPS mode using SSM
# Put the server into FIPS mode using SSM
# Combined server configuration with proper ordering
resource "aws_ssm_document" "server_configuration" {
  name            = "ServerConfiguration"
  document_type   = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: Complete server configuration - Nginx with SSL then FIPS
parameters:
  skipFIPS:
    type: String
    description: Skip FIPS configuration
    default: 'false'
    allowedValues:
      - 'true'
      - 'false'
mainSteps:
- action: aws:runShellScript
  name: installNginx
  inputs:
    runCommand:
    - echo "Installing and configuring Nginx..."
    - sudo dnf update -y
    - sudo dnf install -y nginx
    - sudo mkdir -p /etc/nginx/ssl
    
    # Retrieve cert from SSM (encrypted in transit)
    - |
      aws ssm get-parameter \
        --name "/demo/${var.system_prefix}/nginx/certificate" \
        --with-decryption \
        --region ${var.aws_region} \
        --query 'Parameter.Value' \
        --output text | sudo tee /etc/nginx/ssl/nginx.crt > /dev/null
      sudo chmod 644 /etc/nginx/ssl/nginx.crt
    
    # Retrieve key from SSM (encrypted in transit)  
    - |
      aws ssm get-parameter \
        --name "/demo/${var.system_prefix}/nginx/private_key" \
        --with-decryption \
        --region ${var.aws_region} \
        --query 'Parameter.Value' \
        --output text | sudo tee /etc/nginx/ssl/nginx.key > /dev/null
      sudo chmod 600 /etc/nginx/ssl/nginx.key
    
    # Configure nginx for HTTPS
    - |
      sudo tee /etc/nginx/conf.d/ssl.conf > /dev/null <<EOF
      server {
          listen 443 ssl;
          http2 on;
          server_name _;
          
          ssl_certificate /etc/nginx/ssl/nginx.crt;
          ssl_certificate_key /etc/nginx/ssl/nginx.key;
          
          # SSL configuration
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
          ssl_prefer_server_ciphers off;
          
          root /var/www/html;
          index index.html;
          
          location / {
              try_files \$uri \$uri/ =404;
          }
      }
      
      EOF
    
    - sudo mkdir -p /var/www/html
    - |
      sudo tee /var/www/html/index.html > /dev/null <<EOF
      <!DOCTYPE html>
      <html>
      <head><title>Demo Web Server</title></head>
      <body>
          <h1>Hello from $(hostname)</h1>
          <p>Deployed via SSM Document</p>
          <p>Timestamp: $(date)</p>
      </body>
      </html>
      EOF
    
    # Test nginx configuration before starting
    - sudo nginx -t
    - sudo systemctl enable nginx
    - sudo systemctl restart nginx
    - sudo systemctl status nginx
    - echo "Nginx with SSL installation complete"

- action: aws:runShellScript
  name: enableFIPS
  precondition:
    StringEquals:
      - "{{ skipFIPS }}"
      - "false"
  inputs:
    runCommand:
    - echo "Starting FIPS configuration..."
    - sudo dnf -y install crypto-policies crypto-policies-scripts
    - sudo update-crypto-policies --set FIPS
    - sudo fips-mode-setup --enable
    - echo "FIPS configured, rebooting..."
    - sudo reboot
DOC

  depends_on = [
    aws_ssm_parameter.nginx_cert,
    aws_ssm_parameter.nginx_key
  ]
}

# Association that runs the complete configuration
resource "aws_ssm_association" "server_configuration" {
  name = aws_ssm_document.server_configuration.name
  targets {
    key    = "tag:Role"
    values = ["web-server"]
  }
  
  # Run once on instance launch
  association_name = "ServerConfiguration"
  schedule_expression = "rate(30 days)"  # Re-run monthly (adjust as needed)
}