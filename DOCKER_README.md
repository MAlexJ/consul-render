# Consul Docker Guide

This file explains how to build, run, push, and deploy the Consul container.

## Build locally

```sh
docker build --build-arg CONSUL_VERSION=2.0.0 -t consul-discovery .
```

## Run locally

```sh
docker run --rm \
  -p 10000:10000 \
  -e CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN="$(uuidgen)" \
  consul-discovery
```

Open:

```text
http://localhost:10000
```

## Push to Docker Hub

Tag the image with your Docker Hub username:

```sh
docker tag consul-discovery <dockerhub-user>/consul-discovery:2.0.0
```

Log in to Docker Hub:

```sh
docker login
```

Push the image:

```sh
docker push <dockerhub-user>/consul-discovery:2.0.0
```

## Deploy on Render from Docker Hub

In Render, create a new service and choose an image-backed Docker service.

Use this image:

```text
<dockerhub-user>/consul-discovery:2.0.0
```

Set this environment variable in Render:

```text
CONSUL_ACL_INITIAL_MANAGEMENT_TOKEN=<strong-random-token>
```

Recommended token generation:

```sh
uuidgen
```

or:

```sh
openssl rand -hex 32
```

## Health check

Use one of these in Render:

```text
/v1/status/leader
```

Fallback:

```text
/v1/status/peers
```

## Notes

- `PORT` is set by Render automatically for web services.
- The container exposes the Consul UI/API on the web port only.
- This setup is for a single-node Consul service, not a full multi-node cluster.
