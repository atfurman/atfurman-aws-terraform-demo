# Example configuration for the AWS Infrastructure Monitoring Script
# This file shows various ways to configure and use the monitoring script

# Basic usage examples
BASIC_EXAMPLES = {
    "https_endpoint": "https://demo-lb-123456789.us-east-2.elb.amazonaws.com",
    "http_endpoint": "http://demo-lb-123456789.us-east-2.elb.amazonaws.com",
    "custom_interval": 30,  # seconds between checks
}

# AWS configuration
AWS_CONFIG = {
    "region": "us-east-2",
    "target_tag_key": "Role", 
    "target_tag_value": "web-server",
    "consecutive_failure_threshold": 2,
}

# Monitoring thresholds
MONITORING_CONFIG = {
    "timeout": 30,  # HTTP request timeout in seconds
    "check_interval": 10,  # Default check interval
    "max_restart_attempts": 3,  # Maximum restart attempts per cycle
    "restart_cooldown": 300,  # Seconds to wait before allowing another restart
}

# Logging configuration
LOGGING_CONFIG = {
    "level": "INFO",  # DEBUG, INFO, WARNING, ERROR
    "log_file": "monitor.log",
    "console_output": True,
    "log_format": "%(asctime)s - %(levelname)s - %(message)s"
}

# Example usage patterns:

# 1. Monitor ALB with HTTPS and self-signed certificates
# ./start_monitor.sh https://demo-lb-123456789.us-east-2.elb.amazonaws.com

# 2. Monitor with custom interval (every 5 seconds)
# ./start_monitor.sh https://demo-lb-123456789.us-east-2.elb.amazonaws.com 5

# 3. Monitor HTTP endpoint (no SSL)
# ./start_monitor.sh http://demo-lb-123456789.us-east-2.elb.amazonaws.com

# 4. Set custom AWS region
# AWS_REGION=us-west-2 ./start_monitor.sh https://your-endpoint.com

# 5. Run with debug logging
# Set logging level to DEBUG in monitor.py for detailed output

# 6. Test with integration test
# python test_monitor.py --integration
