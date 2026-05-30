#!/bin/sh
set -eu

: "${PORT:=10000}"
: "${CONSUL_NODE_NAME:=render-consul}"
: "${CONSUL_DATACENTER:=dc1}"
: "${CONSUL_DOMAIN:=consul}"
: "${CONSUL_DATA_DIR:=/consul/data}"
: "${CONSUL_LOG_LEVEL:=INFO}"
: "${CONSUL_BOOTSTRAP_EXPECT:=1}"
: "${CONSUL_UI:=true}"
: "${CONSUL_ENABLE_SCRIPT_CHECKS:=false}"
: "${CONSUL_DISABLE_REMOTE_EXEC:=true}"
: "${CONSUL_LEAVE_ON_TERMINATE:=true}"
: "${CONSUL_SKIP_LEAVE_ON_INTERRUPT:=false}"
: "${CONSUL_DNS_PORT:=8600}"
: "${CONSUL_GRPC_PORT:=8502}"
: "${CONSUL_GRPC_TLS_PORT:=8503}"
: "${CONSUL_ACL_ENABLED:=true}"
: "${CONSUL_ACL_DEFAULT_POLICY:=deny}"
: "${CONSUL_ACL_ENABLE_TOKEN_PERSISTENCE:=true}"

CONFIG_FILE="/tmp/consul-render.hcl"

cat > "$CONFIG_FILE" <<EOF
node_name = "${CONSUL_NODE_NAME}"
datacenter = "${CONSUL_DATACENTER}"
domain = "${CONSUL_DOMAIN}"
data_dir = "${CONSUL_DATA_DIR}"
server = true
bootstrap_expect = ${CONSUL_BOOTSTRAP_EXPECT}
client_addr = "0.0.0.0"
log_level = "${CONSUL_LOG_LEVEL}"
leave_on_terminate = ${CONSUL_LEAVE_ON_TERMINATE}
skip_leave_on_interrupt = ${CONSUL_SKIP_LEAVE_ON_INTERRUPT}
disable_remote_exec = ${CONSUL_DISABLE_REMOTE_EXEC}
enable_script_checks = ${CONSUL_ENABLE_SCRIPT_CHECKS}

ui_config {
  enabled = ${CONSUL_UI}
}

addresses {
  http = "0.0.0.0"
  dns = "0.0.0.0"
  grpc = "0.0.0.0"
  grpc_tls = "0.0.0.0"
}

ports {
  http = ${PORT}
  dns = ${CONSUL_DNS_PORT}
  grpc = ${CONSUL_GRPC_PORT}
  grpc_tls = ${CONSUL_GRPC_TLS_PORT}
}
EOF

if [ "$CONSUL_ACL_ENABLED" = "true" ]; then
  cat >> "$CONFIG_FILE" <<EOF

acl {
  enabled = true
  default_policy = "${CONSUL_ACL_DEFAULT_POLICY}"
  enable_token_persistence = ${CONSUL_ACL_ENABLE_TOKEN_PERSISTENCE}
EOF

  if [ -n "${CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN:-}" ] || [ -n "${CONSUL_ACL_AGENT_TOKEN:-}" ] || [ -n "${CONSUL_ACL_DEFAULT_TOKEN:-}" ]; then
    cat >> "$CONFIG_FILE" <<EOF
  tokens {
EOF
    if [ -n "${CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN:-}" ]; then
      cat >> "$CONFIG_FILE" <<EOF
    initial_management = "${CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN}"
EOF
    fi
    if [ -n "${CONSUL_ACL_AGENT_TOKEN:-}" ]; then
      cat >> "$CONFIG_FILE" <<EOF
    agent = "${CONSUL_ACL_AGENT_TOKEN}"
EOF
    fi
    if [ -n "${CONSUL_ACL_DEFAULT_TOKEN:-}" ]; then
      cat >> "$CONFIG_FILE" <<EOF
    default = "${CONSUL_ACL_DEFAULT_TOKEN}"
EOF
    fi
    cat >> "$CONFIG_FILE" <<EOF
  }
EOF
  fi

  cat >> "$CONFIG_FILE" <<EOF
}
EOF
fi

exec consul agent -config-file="$CONFIG_FILE" "$@"
