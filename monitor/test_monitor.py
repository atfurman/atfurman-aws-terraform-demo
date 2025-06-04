#!/usr/bin/env python3
"""
Test script for the AWS Infrastructure Monitoring Script

This script validates the monitoring functionality without making actual AWS changes.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
import requests

# Add the monitor directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from monitor import HealthMonitor


class TestHealthMonitor(unittest.TestCase):
    """Test cases for the HealthMonitor class."""
    
    def setUp(self):
        """Set up test fixtures."""
        with patch('monitor.boto3.client'):
            self.monitor = HealthMonitor('https://test.example.com', 5)
    
    @patch('monitor.requests.get')
    def test_endpoint_health_success(self, mock_get):
        """Test successful endpoint health check with expected content."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.text = "Welcome to nginx! Deployed via SSM Document"
        mock_get.return_value = mock_response
        
        result = self.monitor.check_endpoint_health()
        self.assertTrue(result)
        mock_get.assert_called_once()
    
    @patch('monitor.requests.get')
    def test_endpoint_health_success_missing_content(self, mock_get):
        """Test endpoint health check with 200 status but missing expected content."""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.text = "Welcome to nginx! This is a basic installation."
        mock_get.return_value = mock_response
        
        result = self.monitor.check_endpoint_health()
        self.assertFalse(result)
        mock_get.assert_called_once()
    
    @patch('monitor.requests.get')
    def test_endpoint_health_failure_status(self, mock_get):
        """Test endpoint health check with bad status code."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_get.return_value = mock_response
        
        result = self.monitor.check_endpoint_health()
        self.assertFalse(result)
    
    @patch('monitor.requests.get')
    def test_endpoint_health_failure_exception(self, mock_get):
        """Test endpoint health check with request exception."""
        mock_get.side_effect = requests.exceptions.ConnectionError("Connection failed")
        
        result = self.monitor.check_endpoint_health()
        self.assertFalse(result)
    
    def test_get_web_server_instances(self):
        """Test getting web server instances."""
        # Mock EC2 response
        mock_response = {
            'Reservations': [
                {
                    'Instances': [
                        {
                            'InstanceId': 'i-1234567890abcdef0',
                            'State': {'Name': 'running'},
                            'LaunchTime': '2024-01-01T00:00:00Z',
                            'PrivateIpAddress': '10.0.1.100',
                            'PublicIpAddress': '54.123.456.789',
                            'Tags': [
                                {'Key': 'Role', 'Value': 'web-server'},
                                {'Key': 'Name', 'Value': 'Demo Web Server'}
                            ]
                        }
                    ]
                }
            ]
        }
        
        self.monitor.ec2_client.describe_instances.return_value = mock_response
        
        instances = self.monitor.get_web_server_instances()
        self.assertEqual(len(instances), 1)
        self.assertEqual(instances[0]['instance_id'], 'i-1234567890abcdef0')
        self.assertEqual(instances[0]['state'], 'running')
        self.assertEqual(instances[0]['tags']['Role'], 'web-server')
    
    def test_restart_instance_success(self):
        """Test successful instance restart."""
        # Mock EC2 waiters
        mock_waiter = Mock()
        self.monitor.ec2_client.get_waiter.return_value = mock_waiter
        
        result = self.monitor.restart_instance('i-1234567890abcdef0')
        self.assertTrue(result)
        
        # Verify stop and start were called
        self.monitor.ec2_client.stop_instances.assert_called_once_with(
            InstanceIds=['i-1234567890abcdef0']
        )
        self.monitor.ec2_client.start_instances.assert_called_once_with(
            InstanceIds=['i-1234567890abcdef0']
        )
    
    def test_restart_instance_failure(self):
        """Test instance restart failure."""
        # Mock exception during stop
        self.monitor.ec2_client.stop_instances.side_effect = Exception("AWS Error")
        
        result = self.monitor.restart_instance('i-1234567890abcdef0')
        self.assertFalse(result)


class TestMonitorScript(unittest.TestCase):
    """Test the monitor script functionality."""
    
    @patch('monitor.HealthMonitor')
    @patch('sys.argv', ['monitor.py', 'https://test.example.com'])
    def test_main_with_valid_endpoint(self, mock_monitor_class):
        """Test main function with valid endpoint."""
        mock_monitor = Mock()
        mock_monitor_class.return_value = mock_monitor
        
        # Import and run main (would normally be called from command line)
        from monitor import main
        
        try:
            main()
        except SystemExit:
            pass  # main() calls sys.exit() on completion
        
        mock_monitor_class.assert_called_once_with('https://test.example.com', 10)
        mock_monitor.run.assert_called_once()
    
    @patch('sys.argv', ['monitor.py', 'invalid-url'])
    def test_main_with_invalid_endpoint(self):
        """Test main function with invalid endpoint."""
        from monitor import main
        
        with self.assertRaises(SystemExit) as cm:
            main()
        
        self.assertEqual(cm.exception.code, 1)


def run_integration_test():
    """Run a simple integration test (requires AWS credentials)."""
    print("Running integration test...")
    
    try:
        # Test with a known endpoint (httpbin for testing)
        # Note: This won't contain "Deployed via SSM Document" so we expect it to fail content check
        monitor = HealthMonitor('https://httpbin.org/html', 1)
        
        # Test endpoint health check (should fail content validation)
        result = monitor.check_endpoint_health()
        if not result:
            print("✓ Content validation test: PASSED (correctly failed due to missing SSM content)")
        else:
            print("✗ Content validation test: FAILED (should have failed content check)")
            return False
        
        # Test getting instances (should work if AWS credentials are available)
        try:
            instances = monitor.get_web_server_instances()
            print(f"✓ Found {len(instances)} web server instances")
        except Exception as e:
            print(f"⚠ Instance discovery test skipped (AWS credentials needed): {e}")
        
        print("✓ Integration test: PASSED")
        return True
        
    except Exception as e:
        print(f"✗ Integration test: FAILED - {e}")
        return False


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Test the monitoring script')
    parser.add_argument('--integration', action='store_true', 
                       help='Run integration tests (requires AWS credentials)')
    args = parser.parse_args()
    
    if args.integration:
        success = run_integration_test()
        sys.exit(0 if success else 1)
    else:
        # Run unit tests
        unittest.main()
