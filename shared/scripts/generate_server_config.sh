#!/bin/bash
# Generate Consul server configuration from template
set -e

DATACENTER=$1
if [ -z "$DATACENTER" ]; then
  echo "Usage: $0 <datacenter>"
  exit 1
fi

TEMPLATE="/ops/shared/config/templates/server.hcl.tpl"
OUTPUT="/etc/consul.d/server.hcl"

sudo mkdir -p /etc/consul.d /opt/consul/data

export DATACENTER

envsubst < "$TEMPLATE" | sudo tee "$OUTPUT" > /dev/null

echo "[INFO] server.hcl written to $OUTPUT"
