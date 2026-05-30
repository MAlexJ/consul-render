# Consul Discovery on Render

Single-node HashiCorp Consul server configured for Render Web Services.

## Deploy on Render.com without a Blueprint

1. Push this repository to GitHub.
2. In Render, click **New +** and choose **Web Service**.
3. Connect your GitHub account and select this repository.
4. Select **Docker** as the runtime.
5. Set **Dockerfile Path** to `./Dockerfile`.
6. Choose the free plan if this is a Free Render deployment.
7. Do not set `PORT`. Render creates it automatically and the container reads it at startup.
8. Add one required environment variable:

```text
CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN=<strong-random-token>
```

A UUID from `uuidgen` is a good value:

```sh
uuidgen
```

You can also generate a strong hex token with OpenSSL:

```sh
openssl rand -hex 32
```

9. Deploy the service.

The Consul UI and HTTP API will be available through the Render service URL. Use the value from `CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN` as the ACL token when logging in to the UI or calling protected API endpoints. This can be either the UUID from `uuidgen` or the hex string from `openssl rand -hex 32`.

## Render health check

In Render's **Advanced** settings, set **Health Check Path** to:

```text
/v1/status/leader
```

If the service is marked unhealthy because the endpoint is blocked by ACLs, try this fallback path:

```text
/v1/status/peers
```

## Optional Render Blueprint

This repository also includes `render.yaml`, but it is optional. Use it only if you want to create the service from a Render Blueprint. For the normal GitHub + Docker flow in the Render UI, you can ignore it.

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
