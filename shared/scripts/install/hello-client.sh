#!/bin/bash

set -e

# Check for cluster ID argument
if [ -z "$1" ]; then
  echo "Usage: $0 <payload-id>"
  exit 1
fi

sudo cp /ops/shared/bin/hello-client /usr/local/bin/hello-client
sudo chmod +x /usr/local/bin/hello-client

PAYLOAD_ID="$1"
SERVICE_PORT="8080"
BINARY_PATH="/usr/local/bin/hello-client"
UNIT_FILE="/etc/systemd/system/hello-client.service"

echo "Installing hello-client for payload ID: $PAYLOAD_ID"

# Ensure binary exists
if [ ! -f "$BINARY_PATH" ]; then
  echo "hello-client binary not found at $BINARY_PATH"
  exit 1
fi

chmod +x "$BINARY_PATH"

# Set HELLO_SERVICE_ADDRESS environment variable
HELLO_SERVICE_ADDRESS="hello-service.service.consul:5050"
export HELLO_SERVICE_ADDRESS

# Create systemd unit
cat > "$UNIT_FILE" <<EOF
[Unit]
Description=Hello Server
After=network.target

[Service]
ExecStart=$BINARY_PATH $PAYLOAD_ID
Restart=on-failure
RestartSec=5
User=ubuntu
WorkingDirectory=/home/ubuntu
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable hello-client
systemctl restart hello-client

# Verify hello server installation
curl -s http://localhost:5050/hello || {
  echo "Hello server installation failed. Exiting."
  exit 1
}
echo "Hello server installed successfully."
