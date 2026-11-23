# Plane A Internal PKI & Public ACME TLS Trait (`traits/tls/`)

## Overview

`traits/tls/` automates both east-west mutual TLS (mTLS) PKI for internal cluster/constellation
communication and north-south public X.509 certificate issuance and renewal.

## Scripts

- **`ca.{sh,cmd}`**: Generates offline or live root/intermediate Certificate Authorities and signs
  SAN-scoped server/client leaf certificates for `etcd`, Patroni PostgreSQL, Redis/Valkey TLS,
  RabbitMQ, and gRPC meshes.
- **`acme.{sh,cmd}`**: Automates Let's Encrypt / ACME HTTP-01 and DNS-01 certificate issuance and
  zero-downtime reload hooks via `_lib/networking/netctl/`.

## Usage

```sh
./libscript.sh trait apply tls
./libscript.sh trait verify tls
```
