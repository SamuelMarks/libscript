# Cluster TLS & PKI Trait (`traits/tls/`)

## Overview

`traits/tls/` automates internal cluster mTLS PKI (`ca.{sh,cmd}`) for etcd, Patroni, and gRPC
services, and delegates public ACME certificate issuance and renewal to `_lib/cloud/cert/`
(`acme.{sh,cmd}`).
