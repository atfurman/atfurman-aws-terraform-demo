# AWS Infrastructure Monitoring Script

This Python monitoring script provides automated health checking and auto-remediation capabilities for AWS infrastructure. It monitors an endpoint and automatically restarts EC2 instances tagged with `Role=web-server` when consecutive health check failures occur.

## Features

- **Endpoint Health Monitoring**: Continuously monitors HTTP/HTTPS endpoints
- **Content Validation**: Verifies that responses contain "Deployed via SSM Document" string
- **Auto-Remediation**: Automatically restarts failed EC2 instances after 2 consecutive failures
- **SSL Support**: Works with self-signed certificates (for demo environments)
- **Graceful Shutdown**: Handles SIGINT and SIGTERM signals properly
- **Logging**: Comprehensive logging to both console and file
- **AWS Integration**: Uses boto3 for EC2 instance management

## Prerequisites

1. **AWS Credentials**: Ensure AWS credentials are configured (via AWS CLI, environment variables, or IAM roles)
2. **Python 3.9+**:
3. **AWS Permissions**: The script requires the following IAM permissions:
   - `ec2:DescribeInstances`
   - `ec2:StartInstances`
   - `ec2:StopInstances`

## Installation

1. Navigate to the monitor directory:
   ```bash
   cd monitor/
   ```

2. Install dependencies using the launcher script (recommended):
   ```bash
   ./start_monitor.sh https://your-endpoint.com
   ```
   
   Or manually install dependencies:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

## Usage

### Quick Start (Recommended)

Use the provided launcher script:

```bash
# Monitor ALB endpoint with default 10-second intervals
./start_monitor.sh https://demo-lb-123456789.us-east-2.elb.amazonaws.com

# Monitor with custom 30-second intervals
./start_monitor.sh https://demo-lb-123456789.us-east-2.elb.amazonaws.com 30
```

### Manual Usage

```bash
# Activate virtual environment
source venv/bin/activate

# Run monitoring script
python monitor.py https://your-endpoint.com

# With custom check interval (30 seconds)
python monitor.py https://your-endpoint.com --interval 30
```

### Example Commands

```bash
# Monitor HTTPS endpoint with self-signed certificate
./start_monitor.sh https://demo-lb-123456789.us-east-2.elb.amazonaws.com

# Monitor HTTP endpoint  
./start_monitor.sh http://demo-lb-123456789.us-east-2.elb.amazonaws.com

# Monitor with 5-second intervals
./start_monitor.sh https://your-app.com 5
```

## How It Works

1. **Health Checking**: Makes HTTP requests to the specified endpoint every N seconds
2. **Content Validation**: Checks that the response contains "Deployed via SSM Document" string to verify proper SSM deployment
3. **Failure Detection**: Tracks consecutive failures (HTTP errors, timeouts, non-200 status codes, or missing content)
4. **Auto-Remediation**: After 2 consecutive failures, automatically restarts all EC2 instances with `Role=web-server` tag
5. **Instance Restart Process**:
   - Stop the instance
   - Wait for instance to stop completely
   - Start the instance
   - Wait for instance to be running
6. **Recovery Detection**: Resets failure counter when endpoint becomes healthy again with proper content

## Configuration

### Environment Variables

- **AWS_REGION** or **AWS_DEFAULT_REGION**: AWS region
- **AWS_ACCESS_KEY_ID**: AWS access key (if not using IAM roles)
- **AWS_SECRET_ACCESS_KEY**: AWS secret key (if not using IAM roles)

### Target Instance Selection

The script automatically discovers and manages EC2 instances with:
- **Tag**: `Role=web-server`
- **State**: `running`, `stopped`, or `stopping`

## Integration with Terraform Infrastructure

This monitoring script works with the accompanying Terraform infrastructure that includes:

- **Application Load Balancer (ALB)** with HTTPS listeners
- **EC2 instances** tagged with `Role=web-server`
- **SSL certificates** (self-signed for demo purposes)

### Getting ALB DNS Name

After deploying with Terraform, get the ALB DNS name:

```bash
pushd ../tf-deploy/
ALB_URL=$(terraform output -raw alb_address)
popd
```

Then use this DNS name with the monitoring script:

```bash
./start_monitor.sh $ALB_URL
```