#!/bin/bash

CONFIG_JSON="/etc/consul.d/client_config.json"
TEMPLATE="/ops/shared/config/templates/consul.hcl.tpl"
OUTPUT="/etc/consul.d/consul.hcl"

# Extract required values using jq
DATACENTER=$(jq -r '.datacenter' "$CONFIG_JSON")
LOG_LEVEL=$(jq -r '.log_level' "$CONFIG_JSON")
SERVER=$(jq -r '.server' "$CONFIG_JSON")
UI=$(jq -r '.ui' "$CONFIG_JSON")

ENCRYPT=$(jq -r '.encrypt' "$CONFIG_JSON")
ENCRYPT_VERIFY_INCOMING=$(jq -r '.encrypt_verify_incoming' "$CONFIG_JSON")
ENCRYPT_VERIFY_OUTGOING=$(jq -r '.encrypt_verify_outgoing' "$CONFIG_JSON")

RETRY_JOIN=$(jq -r '.retry_join[0]' "$CONFIG_JSON" | sed 's/^/  "/;s/$/"/' | paste -sd, -)

ACL_ENABLED=$(jq -r '.acl.enabled' "$CONFIG_JSON")
ACL_DOWN_POLICY=$(jq -r '.acl.down_policy' "$CONFIG_JSON")
ACL_DEFAULT_POLICY=$(jq -r '.acl.default_policy' "$CONFIG_JSON")

AUTO_ENCRYPT_TLS=$(jq -r '.auto_encrypt.tls' "$CONFIG_JSON")

TLS_CA_FILE="/etc/consul.d/ca.pem"
TLS_VERIFY_OUTGOING=$(jq -r '.tls.defaults.verify_outgoing' "$CONFIG_JSON")

CONNECT_ENABLED=$(jq -r '.connect.enabled' "$CONFIG_JSON")
CONSUL_HTTP_TOKEN=$(cat /etc/consul.d/admin_token.txt)

# Export all for envsubst
export DATACENTER LOG_LEVEL SERVER UI ENCRYPT ENCRYPT_VERIFY_INCOMING ENCRYPT_VERIFY_OUTGOING
export RETRY_JOIN ACL_ENABLED ACL_DOWN_POLICY ACL_DEFAULT_POLICY
export AUTO_ENCRYPT_TLS TLS_CA_FILE TLS_VERIFY_OUTGOING CONNECT_ENABLED CONSUL_HTTP_TOKEN

# Generate HCL
envsubst < "$TEMPLATE" > "$OUTPUT"

echo "[INFO] consul.hcl written to $OUTPUT"
