# Consul Discovery on Render

Single-node HashiCorp Consul server configured for Render Web Services.

## Deploy

1. Push this repository to GitHub.
2. Create a new Render Web Service from the repository, or use the `render.yaml` blueprint.
3. Use Docker runtime and the free plan.
4. Keep `PORT` unset unless you need to override Render's default.
5. Store `CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN` as a secret env var. A UUID from `uuidgen` is a good value.

## Runtime env vars

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `10000` | HTTP/UI port Render routes to the service. Render sets this automatically. |
| `CONSUL_VERSION` | `2.0.0` | Docker image tag used at build time. |
| `CONSUL_NODE_NAME` | `render-consul` | Consul node name. |
| `CONSUL_DATACENTER` | `dc1` | Consul datacenter name. |
| `CONSUL_DOMAIN` | `consul` | Consul DNS domain. |
| `CONSUL_LOG_LEVEL` | `INFO` | Consul log level. |
| `CONSUL_BOOTSTRAP_EXPECT` | `1` | Single-server bootstrap count. |
| `CONSUL_UI` | `true` | Enables the Consul UI. |
| `CONSUL_ACL_ENABLED` | `true` | Enables Consul ACLs. |
| `CONSUL_ACL_DEFAULT_POLICY` | `deny` | Default ACL policy. |
| `CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN` | empty | Initial management token. Set this before exposing the service. Use a strong UUID/string accepted by Consul. |

## Local run

```sh
docker build --build-arg CONSUL_VERSION=2.0.0 -t render-consul .
docker run --rm -p 10000:10000 --env-file .env.example render-consul
```

Open `http://localhost:10000`.

## Render limitations

Render Web Services expose HTTP/HTTPS routing for the configured web port. This setup publishes Consul UI/API through `PORT`, but it does not expose Consul gossip, RPC, or DNS ports as a normal Consul cluster would. Treat this as a lightweight single-node discovery/API service, not a production multi-node Consul cluster.
