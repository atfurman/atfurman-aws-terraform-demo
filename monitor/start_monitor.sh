#!/bin/bash
# Monitor script launcher
# This script sets up the environment and launches the Python monitoring script

# Check for endpoint parameter
if [ $# -eq 0 ]; then
    echo "Usage: $0 <endpoint_url> [check_interval]"
    echo "Example: $0 https://demo-lb-123456789.us-east-2.elb.amazonaws.com"
    exit 1
fi

ENDPOINT="$1"
INTERVAL="${2:-10}"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if virtual environment exists, if not create it
VENV_DIR="${SCRIPT_DIR}/venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install dependencies if needed
if [ ! -f "$VENV_DIR/.deps_installed" ]; then
    echo "Installing Python dependencies..."
    pip install -r "${SCRIPT_DIR}/requirements.txt"
    touch "$VENV_DIR/.deps_installed"
fi

# Set AWS region if not already set
if [ -z "$AWS_REGION" ] && [ -z "$AWS_DEFAULT_REGION" ]; then
    export AWS_REGION="us-east-2"
    echo "AWS_REGION set to: $AWS_REGION"
fi

echo "Starting health monitor..."
echo "Endpoint: $ENDPOINT"
echo "Check interval: ${INTERVAL} seconds"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Run the monitoring script
python "${SCRIPT_DIR}/monitor.py" "$ENDPOINT" --interval "$INTERVAL"
