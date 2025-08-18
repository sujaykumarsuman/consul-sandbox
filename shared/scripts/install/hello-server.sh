#!/bin/bash

set -e

# Check for cluster ID argument
if [ -z "$1" ]; then
  echo "Usage: $0 <payload-id>"
  exit 1
fi

sudo cp /ops/shared/bin/hello-server /usr/local/bin/hello-server
sudo chmod +x /usr/local/bin/hello-server

PAYLOAD_ID="$1"
SERVICE_PORT="5050"
BINARY_PATH="/usr/local/bin/hello-server"
UNIT_FILE="/etc/systemd/system/hello-server.service"

echo "Installing hello-server for payload ID: $PAYLOAD_ID"

# Ensure binary exists
if [ ! -f "$BINARY_PATH" ]; then
  echo "hello-server binary not found at $BINARY_PATH"
  exit 1
fi

chmod +x "$BINARY_PATH"

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
systemctl enable hello-server
systemctl restart hello-server

# Verify hello server installation
curl -s http://localhost:5050/hello || {
  echo "Hello server installation failed. Exiting."
  exit 1
}
echo "Hello server installed successfully."

# Register service with Consul
echo "Registering hello-server service with Consul"
cat > /etc/consul.d/hello-server.json <<EOF
{
  "service": {
    "name": "hello-server",
    "id": "hello-server-$PAYLOAD_ID",
    "port": $SERVICE_PORT,
    "tags": ["payload:$PAYLOAD_ID"],
    "check": {
      "http": "http://localhost:$SERVICE_PORT/hello",
      "interval": "10s",
      "timeout": "5s"
    }
  }
}
EOF

sleep 2

# Reload Consul configuration
echo "Reloading Consul configuration"
consul reload || {
  echo "Failed to reload Consul configuration. Exiting."
  exit 1
}
