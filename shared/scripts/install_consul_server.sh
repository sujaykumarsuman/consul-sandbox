#!/bin/bash
# Install Consul server on an Ubuntu system
set -e

CONSUL_VERSION=1.18.7
DATACENTER=$1
if [ -z "$DATACENTER" ]; then
  echo "Usage: $0 <datacenter>"
  exit 1
fi

sudo apt-get update
sudo apt-get install -y unzip curl

curl -L -o /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
sudo unzip /tmp/consul.zip -d /usr/local/bin
sudo chmod +x /usr/local/bin/consul

sudo mkdir -p /etc/consul.d
cat <<CFG | sudo tee /etc/consul.d/server.hcl
server = true
bootstrap_expect = 1
datacenter = "${DATACENTER}"
ui = true
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
CFG

cat <<'SERVICE' | sudo tee /etc/systemd/system/consul.service
[Unit]
Description=Consul Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl enable consul
sudo systemctl start consul
