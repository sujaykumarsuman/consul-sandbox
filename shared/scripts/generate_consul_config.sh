#!/bin/bash

# Optionally override the config JSON, template, and output path
CONFIG_JSON=${1:-/etc/consul.d/client_config.json}
TEMPLATE=${2:-/ops/shared/config/templates/client/consul.hcl.tpl}
OUTPUT=${3:-/etc/consul.d/consul.hcl}

# Extract required values using jq
DATACENTER=$(jq -r '.datacenter' "$CONFIG_JSON")
LOG_LEVEL=$(jq -r '.log_level' "$CONFIG_JSON")
SERVER=$(jq -r '.server' "$CONFIG_JSON")
UI=$(jq -r '.ui // false' "$CONFIG_JSON")

CLIENT_ADDR=$(jq -r '.client_addr // "0.0.0.0"' "$CONFIG_JSON")
BIND_ADDR=$(jq -r '.bind_addr // "0.0.0.0"' "$CONFIG_JSON")
BOOTSTRAP_EXPECT=$(jq -r '.bootstrap_expect // 1' "$CONFIG_JSON")

ENCRYPT=$(jq -r '.encrypt' "$CONFIG_JSON")
ENCRYPT_VERIFY_INCOMING=$(jq -r '.encrypt_verify_incoming' "$CONFIG_JSON")
ENCRYPT_VERIFY_OUTGOING=$(jq -r '.encrypt_verify_outgoing' "$CONFIG_JSON")

# Build retry_join block
if jq -e '.retry_join | length > 0' "$CONFIG_JSON" > /dev/null; then
  RETRY_JOIN_BLOCK=$(jq -r '.retry_join[]' "$CONFIG_JSON" | sed 's/^/  "/;s/$/"/' | paste -sd, -)
  RETRY_JOIN_BLOCK=$(printf 'retry_join = [\n%s\n]\n' "$RETRY_JOIN_BLOCK")
else
  RETRY_JOIN_BLOCK=""
fi

# Build ACL block
ACL_BLOCK=""
ACL_ENABLED=$(jq -r '.acl.enabled // false' "$CONFIG_JSON")
if [ "$ACL_ENABLED" = "true" ]; then
  CONSUL_HTTP_TOKEN=""
  if [ -f /etc/consul.d/admin_token.txt ]; then
    CONSUL_HTTP_TOKEN=$(cat /etc/consul.d/admin_token.txt)
  fi
  if [ -n "$CONSUL_HTTP_TOKEN" ]; then
    ACL_BLOCK=$(cat <<EOF
acl {
  enabled = true
  tokens {
    agent = "$CONSUL_HTTP_TOKEN"
  }
}
EOF
)
  else
    ACL_BLOCK=$(cat <<'EOF'
acl {
  enabled = true
}
EOF
)
  fi
fi

TLS_CA_FILE="/etc/consul.d/ca.pem"
TLS_VERIFY_OUTGOING=$(jq -r '.tls.defaults.verify_outgoing // false' "$CONFIG_JSON")

CONNECT_ENABLED=$(jq -r '.connect.enabled // false' "$CONFIG_JSON")
LICENSE_PATH="/etc/consul.d/license.hclic"

# Export all for envsubst
export DATACENTER LOG_LEVEL SERVER UI ENCRYPT ENCRYPT_VERIFY_INCOMING ENCRYPT_VERIFY_OUTGOING
export RETRY_JOIN_BLOCK ACL_BLOCK TLS_CA_FILE TLS_VERIFY_OUTGOING CONNECT_ENABLED LICENSE_PATH
export CLIENT_ADDR BIND_ADDR BOOTSTRAP_EXPECT

# Generate HCL
envsubst < "$TEMPLATE" > "$OUTPUT"

echo "[INFO] consul.hcl written to $OUTPUT"
