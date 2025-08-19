bootstrap_expect = ${BOOTSTRAP_EXPECT}
datacenter = "${DATACENTER}"
log_level  = "${LOG_LEVEL}"
server     = ${SERVER}
ui         = ${UI}
client_addr = "${CLIENT_ADDR}"
bind_addr   = "${BIND_ADDR}"
data_dir   = "/opt/consul/data"
license_path = "${LICENSE_PATH}"

encrypt = "${ENCRYPT}"
encrypt_verify_incoming = ${ENCRYPT_VERIFY_INCOMING}
encrypt_verify_outgoing = ${ENCRYPT_VERIFY_OUTGOING}

retry_join = [
  ${RETRY_JOIN}
]

acl {
  enabled        = ${ACL_ENABLED}
  down_policy    = "${ACL_DOWN_POLICY}"
  default_policy = "${ACL_DEFAULT_POLICY}"
  tokens {
    agent = "${CONSUL_HTTP_TOKEN}"
  }
}

ui_config = {
  enabled = ${UI}
}

auto_encrypt {
  tls = ${AUTO_ENCRYPT_TLS}
}

tls {
  defaults {
    ca_file = "${TLS_CA_FILE}"
    verify_outgoing = ${TLS_VERIFY_OUTGOING}
  }
}

connect {
  enabled = ${CONNECT_ENABLED}
}
