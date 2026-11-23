# Plane A Service Discovery & Private DNS Trait (`traits/discovery/`)

## Overview

`traits/discovery/` provides uniform service endpoint registration and name resolution across static
sysroots, local LANs, consensus KV stores, and cloud private DNS zones.

## Scripts

- **`hosts.{sh,cmd}`**: Idempotently renders deterministic cluster peer blocks in `/etc/hosts` (or
  `C:\Windows\System32\drivers\etc\hosts` and `T3` `--sysroot` targets).
- **`mdns.{sh,cmd}`**: Publishes local service records over mDNS / DNS-SD (`avahi-daemon`, macOS
  `dns-sd`).
- **`consul_etcd.{sh,cmd}`**: Registers service endpoints and TTL health checks in HashiCorp Consul
  or `etcd` KV namespaces.
- **`cloud_dns.{sh,cmd}`**: Synchronizes `A`/`AAAA`/`SRV`/`CNAME` records in AWS Route53, Google
  Cloud DNS, and Azure Private DNS zones.
- **`agent.{sh,cmd}`**: Top-level discovery trait reconciler invoked by `traits/engine.{sh,cmd}`.

## Usage

```sh
./libscript.sh trait apply discovery
./libscript.sh trait verify discovery
```
