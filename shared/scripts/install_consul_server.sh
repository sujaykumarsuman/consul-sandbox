#!/bin/bash
# Install Consul server on an Ubuntu system
set -e

CONSUL_VERSION=1.18.7
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

sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y universe && sudo apt-get -y update
sudo apt-get install -y unzip jq curl

# Install HashiCorp Apt Repository and Consul Enterprise
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
echo "Installing Consul Enterprise"
sudo apt-get update && sudo apt-get -y install consul-enterprise=$CONSUL_VERSION*

# Install Consul Enterprise license
echo "Installing Consul Enterprise license"
echo "$CONSUL_ENT_LICENSE" | sudo tee /etc/consul.d/license.hclic > /dev/null
sudo chmod 644 /etc/consul.d/license.hclic

# Copy pre-rendered configuration bundle
CONFIG_DIR="/ops/shared/config/server_config/${DATACENTER}"
if [ ! -d "$CONFIG_DIR" ]; then
  echo "Configuration directory not found: $CONFIG_DIR"
  exit 1
fi
sudo cp "${CONFIG_DIR}/server_config.json" /etc/consul.d/client_config.json
sudo cp "${CONFIG_DIR}/ca.pem" /etc/consul.d/ca.pem
sudo cp "${CONFIG_DIR}/admin_token.txt" /etc/consul.d/admin_token.txt

# Generate final Consul configuration
echo "Generating Consul server configuration"
sudo bash /ops/shared/scripts/generate_consul_config.sh \
  /etc/consul.d/client_config.json \
  /ops/shared/config/templates/server/consul.hcl.tpl

cat <<'SERVICE' | sudo tee /etc/systemd/system/consul.service
[Unit]
Description=Consul Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl enable consul.service && sleep 5
sudo systemctl start consul.service
