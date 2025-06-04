#!/usr/bin/env python3
"""
Simple validation test for the content checking feature
"""

import sys
import os

# Add the monitor directory to the path  
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Mock the external dependencies for this test
class MockResponse:
    def __init__(self, status_code, text):
        self.status_code = status_code
        self.text = text

def mock_requests_get(url, timeout=None, verify=None):
    if "success" in url:
        return MockResponse(200, "Welcome to nginx! Deployed via SSM Document")
    elif "missing-content" in url:
        return MockResponse(200, "Welcome to nginx! Standard installation")
    else:
        raise Exception("Connection failed")

# Mock boto3 and requests
sys.modules['boto3'] = type(sys)('mock_boto3')
sys.modules['requests'] = type(sys)('mock_requests')
sys.modules['requests'].get = mock_requests_get
sys.modules['requests'].exceptions = type(sys)('mock_exceptions')
sys.modules['requests'].exceptions.RequestException = Exception

# Mock boto3 client
class MockEC2Client:
    def describe_instances(self, **kwargs):
        return {'Reservations': []}

def mock_boto3_client(service, region_name=None):
    return MockEC2Client()

sys.modules['boto3'].client = mock_boto3_client

# Now import and test the monitor
from monitor import HealthMonitor

def test_content_validation():
    """Test the content validation functionality"""
    print("Testing content validation feature...")
    
    # Test successful case (contains SSM string)
    monitor = HealthMonitor('https://success.example.com', 10)
    result = monitor.check_endpoint_health()
    assert result == True, "Should pass with SSM content"
    print("✓ Success case: PASSED")
    
    # Test failure case (missing SSM string)  
    monitor = HealthMonitor('https://missing-content.example.com', 10)
    result = monitor.check_endpoint_health()
    assert result == False, "Should fail without SSM content"
    print("✓ Missing content case: PASSED")
    
    # Test connection failure case
    monitor = HealthMonitor('https://failure.example.com', 10)
    result = monitor.check_endpoint_health()
    assert result == False, "Should fail on connection error"
    print("✓ Connection failure case: PASSED")
    
    print("\n✓ All content validation tests PASSED!")

if __name__ == "__main__":
    test_content_validation()
