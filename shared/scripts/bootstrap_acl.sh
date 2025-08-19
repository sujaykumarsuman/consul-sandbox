#!/bin/bash
# Bootstrap ACLs after Consul server startup and distribute the token
set -e

DATACENTER=$1
if [ -z "$DATACENTER" ]; then
  echo "Usage: $0 <datacenter>"
  exit 1
fi

# Skip if token already exists
if [ -s /etc/consul.d/admin_token.txt ]; then
  echo "[INFO] ACL token already bootstrapped"
  exit 0
fi

CONFIG_BASE=/ops/shared/config
SERVER_DIR="${CONFIG_BASE}/server_config/${DATACENTER}"
CLIENT_DIR="${CONFIG_BASE}/client_config/${DATACENTER}"

# Wait for Consul to be ready
until consul info >/dev/null 2>&1; do
  echo "[INFO] waiting for Consul to be ready..."
  sleep 2
done

# Bootstrap ACL system
TOKEN=$(consul acl bootstrap | awk '/SecretID/ {print $2}')

# Distribute token
echo "$TOKEN" | tee "${SERVER_DIR}/admin_token.txt" > "${CLIENT_DIR}/admin_token.txt"
sudo cp "${SERVER_DIR}/admin_token.txt" /etc/consul.d/admin_token.txt

# Apply token to running agent
consul acl set-agent-token agent "$TOKEN"

# Regenerate config to persist token
sudo /ops/shared/scripts/generate_consul_config.sh \
  /etc/consul.d/client_config.json \
  /ops/shared/config/templates/server/consul.hcl.tpl

# Restart Consul to load new config
sudo systemctl restart consul.service
