# Plane A Structured Log Shipping Trait (`traits/logging/`)

## Overview

`traits/logging/` configures node-wide and per-component structured log collection, rotation, and
forwarding without coupling `T1` components to a specific observability vendor.

## Scripts

- **`agent.{sh,cmd}`**: Emits collector pipelines for `_lib/logging/fluentbit`, Vector, or native
  `syslog`/`journald` forwarding to Loki, Elasticsearch/OpenSearch, S3/GCS archives, or OTLP
  endpoints (offline in `--sysroot` mode or live with service reload).

## Usage

```sh
./libscript.sh trait apply logging
./libscript.sh trait verify logging
```
