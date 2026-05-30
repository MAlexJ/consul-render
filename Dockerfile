ARG CONSUL_VERSION=2.0.0
FROM hashicorp/consul:${CONSUL_VERSION}

COPY docker-entrypoint-render.sh /usr/local/bin/docker-entrypoint-render.sh

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O - "http://127.0.0.1:${PORT:-10000}/v1/status/leader" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-render.sh"]
