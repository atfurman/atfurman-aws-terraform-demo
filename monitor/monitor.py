"""
AWS Infrastructure Monitoring Script

This script monitors an endpoint and automatically restarts EC2 instances
with the 'web-server' role tag if consecutive health checks fail.

The health check validates both HTTP status (200) and page content 
(must contain "Deployed via SSM Document" string).

Usage:
    python monitor.py <endpoint_url>

Example:
    python monitor.py https://example.com/health
"""

import argparse
import boto3
import logging
import os
import requests
import signal
import sys
import time
from datetime import datetime
from typing import List, Dict, Optional


class HealthMonitor:
    """Monitor endpoint health and manage EC2 instances for auto-remediation."""
    
    def __init__(self, endpoint: str, check_interval: int = 10):
        """Initialize the health monitor.
        
        Args:
            endpoint: The URL endpoint to monitor
            check_interval: Seconds between health checks (default: 10)
        """
        self.endpoint = endpoint
        self.check_interval = check_interval
        self.consecutive_failures = 0
        self.running = True
        
        # AWS setup
        self.region = os.environ.get('AWS_REGION', os.environ.get('AWS_DEFAULT_REGION', 'us-east-1'))
        self.ec2_client = boto3.client('ec2', region_name=self.region)
        
        # Setup logging
        self._setup_logging()
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        self.logger.info(f"Health monitor initialized for endpoint: {self.endpoint}")
        self.logger.info(f"AWS Region: {self.region}")
        self.logger.info(f"Check interval: {self.check_interval} seconds")
    
    def _setup_logging(self):
        """Configure logging with timestamps and proper formatting."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler('monitor.log')
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully."""
        self.logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
    
    def check_endpoint_health(self) -> bool:
        """Check if the endpoint is healthy.
        
        Returns:
            True if endpoint responds successfully and contains expected content, False otherwise
        """
        try:
            response = requests.get(
                self.endpoint,
                timeout=30,
                verify=False  # Allow self-signed certificates for demo
            )
            
            if response.status_code == 200:
                # Check if the response contains the expected SSM deployment string
                if "Deployed via SSM Document" in response.text:
                    self.logger.info(f"✓ Endpoint healthy - Status: {response.status_code}, SSM deployment confirmed")
                    return True
                else:
                    self.logger.warning(f"✗ Endpoint unhealthy - Status: {response.status_code}, but missing 'Deployed via SSM Document' string")
                    return False
            else:
                self.logger.warning(f"✗ Endpoint unhealthy - Status: {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            self.logger.error(f"✗ Endpoint check failed: {str(e)}")
            return False
    
    def get_web_server_instances(self) -> List[Dict]:
        """Get all EC2 instances with Role=web-server tag.
        
        Returns:
            List of instance dictionaries with relevant information
        """
        try:
            response = self.ec2_client.describe_instances(
                Filters=[
                    {
                        'Name': 'tag:Role',
                        'Values': ['web-server']
                    },
                    {
                        'Name': 'instance-state-name',
                        'Values': ['running', 'stopped', 'stopping']
                    }
                ]
            )
            
            instances = []
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    # Extract relevant instance information
                    instance_info = {
                        'instance_id': instance['InstanceId'],
                        'state': instance['State']['Name'],
                        'launch_time': instance.get('LaunchTime'),
                        'private_ip': instance.get('PrivateIpAddress'),
                        'public_ip': instance.get('PublicIpAddress'),
                        'tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    }
                    instances.append(instance_info)
            
            return instances
            
        except Exception as e:
            self.logger.error(f"Failed to get web server instances: {str(e)}")
            return []
    
    def restart_instance(self, instance_id: str) -> bool:
        """Restart a specific EC2 instance.
        
        Args:
            instance_id: The EC2 instance ID to restart
            
        Returns:
            True if restart was initiated successfully, False otherwise
        """
        try:
            self.logger.info(f"Attempting to restart instance: {instance_id}")
            
            # Stop the instance first
            self.ec2_client.stop_instances(InstanceIds=[instance_id])
            self.logger.info(f"Stop command sent for instance: {instance_id}")
            
            # Wait for instance to stop
            waiter = self.ec2_client.get_waiter('instance_stopped')
            self.logger.info(f"Waiting for instance {instance_id} to stop...")
            waiter.wait(
                InstanceIds=[instance_id],
                WaiterConfig={'Delay': 15, 'MaxAttempts': 20}
            )
            
            # Start the instance
            self.ec2_client.start_instances(InstanceIds=[instance_id])
            self.logger.info(f"Start command sent for instance: {instance_id}")
            
            # Wait for instance to be running
            waiter = self.ec2_client.get_waiter('instance_running')
            self.logger.info(f"Waiting for instance {instance_id} to start...")
            waiter.wait(
                InstanceIds=[instance_id],
                WaiterConfig={'Delay': 15, 'MaxAttempts': 20}
            )
            
            self.logger.info(f"✓ Instance {instance_id} restarted successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"✗ Failed to restart instance {instance_id}: {str(e)}")
            return False
    
    def restart_web_servers(self):
        """Restart all web server instances."""
        instances = self.get_web_server_instances()
        
        if not instances:
            self.logger.warning("No web server instances found with Role=web-server tag")
            return
        
        self.logger.info(f"Found {len(instances)} web server instance(s) to restart")
        
        restart_count = 0
        for instance in instances:
            instance_id = instance['instance_id']
            instance_state = instance['state']
            
            self.logger.info(f"Instance {instance_id} current state: {instance_state}")
            
            if instance_state in ['running', 'stopped']:
                if self.restart_instance(instance_id):
                    restart_count += 1
            else:
                self.logger.warning(f"Skipping instance {instance_id} in state: {instance_state}")
        
        self.logger.info(f"Restart operation completed. Successfully restarted {restart_count} instances")
    
    def run(self):
        """Main monitoring loop."""
        self.logger.info("Starting health monitoring...")
        
        while self.running:
            try:
                # Check endpoint health
                is_healthy = self.check_endpoint_health()
                
                if is_healthy:
                    # Reset failure counter on successful check
                    if self.consecutive_failures > 0:
                        self.logger.info(f"Endpoint recovered after {self.consecutive_failures} consecutive failures")
                    self.consecutive_failures = 0
                else:
                    # Increment failure counter
                    self.consecutive_failures += 1
                    self.logger.warning(f"Consecutive failures: {self.consecutive_failures}")
                    
                    # Trigger remediation after 2 consecutive failures
                    if self.consecutive_failures >= 2:
                        self.logger.error("Two consecutive failures detected - triggering auto-remediation")
                        self.restart_web_servers()
                        # Reset counter after remediation attempt
                        self.consecutive_failures = 0
                
                # Wait for next check
                if self.running:
                    time.sleep(self.check_interval)
                    
            except KeyboardInterrupt:
                self.logger.info("Monitoring interrupted by user")
                break
            except Exception as e:
                self.logger.error(f"Unexpected error in monitoring loop: {str(e)}")
                time.sleep(self.check_interval)
        
        self.logger.info("Health monitoring stopped")


def main():
    """Main entry point for the monitoring script."""
    parser = argparse.ArgumentParser(
        description="Monitor endpoint health and restart EC2 instances on failure",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python monitor.py https://example.com/health
    python monitor.py http://load-balancer.amazonaws.com:8080/status
    python monitor.py https://demo-lb-123456789.us-east-2.elb.amazonaws.com
        """
    )
    
    parser.add_argument(
        'endpoint',
        help='The endpoint URL to monitor (e.g., https://example.com/health)'
    )
    
    parser.add_argument(
        '--interval',
        type=int,
        default=10,
        help='Check interval in seconds (default: 10)'
    )
    
    args = parser.parse_args()
    
    # Validate endpoint URL
    if not args.endpoint.startswith(('http://', 'https://')):
        print("Error: Endpoint must start with http:// or https://")
        sys.exit(1)
    
    # Create and run monitor
    monitor = HealthMonitor(args.endpoint, args.interval)
    
    try:
        monitor.run()
    except Exception as e:
        print(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()