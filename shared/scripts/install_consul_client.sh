#!/bin/bash
# Install Consul client on an Ubuntu system

set -e

SHARED_DIR=/ops/shared
CONFIG_DIR=${SHARED_DIR}/config
CONSUL_VERSION=1.18.7
ENVOY_VERSION=1.27.7
CONSUL_ENT_LICENSE=$1
if [ -z "$CONSUL_ENT_LICENSE" ]; then
    echo "Usage: $0 <consul_ent_license> <datacenter>"
    exit 1
fi
DATACENTER=$2
if [ -z "$DATACENTER" ]; then
    echo "Usage: $0 <consul_ent_license> <datacenter>"
    exit 1
fi

CONFIG_FILE="${SHARED_DIR}/config/client_config/${DATACENTER}/client_config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Ensure connect is enabled in the configuration, if not then enable it
if ! jq -e '.connect.enabled' "${CONFIG_FILE}" > /dev/null; then
    echo "Connect is not enabled in the configuration file: $CONFIG_FILE"
    echo "Enabling Connect in the configuration file"
    jq '.connect.enabled = true' "${CONFIG_FILE}" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"
fi

# Ensure the /etc/consul.d directory exists
sudo mkdir -p /etc/consul.d
sudo mkdir -p /opt/consul/data

# Wait for CA cert and admin token to be available
until [ -s "${CONFIG_DIR}/client_config/${DATACENTER}/ca.pem" ]; do
    echo "Waiting for CA certificate..."
    sleep 2
done

until [ -s "${CONFIG_DIR}/client_config/${DATACENTER}/admin_token.txt" ]; do
    echo "Waiting for admin token..."
    sleep 2
done

# Copy the client configuration, CA file, and admin token to /etc/consul.d
echo "Copying client configuration and secrets to /etc/consul.d"
sudo cp "${CONFIG_FILE}" /etc/consul.d/
sudo cp "${CONFIG_DIR}/client_config/${DATACENTER}/ca.pem" /etc/consul.d/
sudo cp "${CONFIG_DIR}/client_config/${DATACENTER}/admin_token.txt" /etc/consul.d/

# Wait for network
sleep 15

sudo apt-get install -y software-properties-common
sudo add-apt-repository -y universe && sudo apt-get -y update
sudo apt-get install -y unzip tree redis-tools jq curl tmux
sudo apt-get clean

# Install HashiCorp Apt Repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

echo "Installing consul and envoy"
# Install Consul only
sudo apt-get update && sudo apt-get -y install consul-enterprise=$CONSUL_VERSION* hashicorp-envoy=$ENVOY_VERSION*

# Install Consul Enterprise license
echo "Installing Consul Enterprise license"
echo "$CONSUL_ENT_LICENSE" | sudo tee /etc/consul.d/license.hclic > /dev/null
sudo chmod 644 /etc/consul.d/license.hclic

# Verify Consul installation
echo "Verifying Consul installation"
if ! consul version; then
    echo "Consul installation failed. Exiting."
    exit 1
fi
echo "Consul installed successfully."

# Set consul environment variables for consul cli
echo "Setting Consul http addr"
CONSUL_HTTP_ADDR=$(jq -r '.retry_join[0]' "${CONFIG_FILE}")
echo "export CONSUL_HTTP_ADDR=https://${CONSUL_HTTP_ADDR}" | sudo tee -a /home/ubuntu/.bashrc > /dev/null
echo "Setting Consul admin token"
CONSUL_HTTP_TOKEN=$(cat "${CONFIG_DIR}/client_config/${DATACENTER}/admin_token.txt")
echo "export CONSUL_HTTP_TOKEN=${CONSUL_HTTP_TOKEN}" | sudo tee -a /home/ubuntu/.bashrc > /dev/null

# Generate Consul configuration file
echo "Generating Consul configuration file"
sudo bash /ops/shared/scripts/generate_consul_config.sh

# Start Consul client service
echo "Starting Consul client service"
sudo systemctl enable consul.service && sleep 5
sudo systemctl start consul.service && sleep 15

# Verify Consul client service status
echo "Verifying Consul client service status"
if ! systemctl is-active --quiet consul.service; then
    echo "Consul client service failed to start. Exiting."
    exit 1
fi
echo "Consul client service started successfully."
