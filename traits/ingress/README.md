# Plane A North-South Ingress Routing Trait (`traits/ingress/`)

## Overview

`traits/ingress/` binds `T5` application and constellation endpoints to reverse-proxy and
load-balancer frontends by delegating declarative HTTP, WebSocket, gRPC, and TCP stream routes to
`_lib/networking/netctl/`.

## Scripts

- **`route.{sh,cmd}`**: Compiles ingress route tables, TLS termination bindings, health checks, and
  zero-downtime reload actions across Nginx, Caddy, Apache `httpd`, Traefik, HAProxy, and Windows
  IIS.

## Usage

```sh
./libscript.sh trait apply ingress
./libscript.sh trait verify ingress
./libscript.sh trait teardown ingress
```
