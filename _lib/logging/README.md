# Observability, Metrics & Log Shippers (`_lib/logging/`)

## Overview

**Tier Scope**: `T1`

Log routers, metrics time-series engines, dashboards, and ML training telemetry servers
(`fluentbit`, `vector`, `loki`, `prometheus`, `otel-collector`, `grafana`, `tensorboard`).

Each subdirectory in `_lib/logging/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/logging/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh fluentbit --help
./libscript.sh install fluentbit latest
./_lib/logging/fluentbit/cli.sh test
```

```cmd
.\libscript.cmd fluentbit --help
.\libscript.cmd install fluentbit latest
.\_lib\logging\fluentbit\cli.cmd test
```

## Components (7)

<!-- BEGIN_COMPONENTS -->

- [`fluentbit`](./fluentbit/README.md) (`T1` — `userland-package`, `service-daemon`): A super fast,
  lightweight, and highly scalable logging and metrics processor and forwarder.
- [`grafana`](./grafana/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  analytics, interactive visualization, and alerting web platform for metrics, logs, and traces.
- [`loki`](./loki/README.md) (`T1` — `userland-package`, `service-daemon`): Horizontally scalable,
  highly available, multi-tenant log aggregation system inspired by Prometheus.
- [`otel-collector`](./otel-collector/README.md) (`T1` — `userland-package`, `service-daemon`):
  Vendor-agnostic proxy receiving, processing, and exporting OpenTelemetry traces, metrics, and
  logs.
- [`prometheus`](./prometheus/README.md) (`T1` — `userland-package`, `service-daemon`): Cloud-native
  dimensional time-series monitoring server, PromQL query engine, and alerting toolkit.
- [`tensorboard`](./tensorboard/README.md) (`T1` — `userland-package`, `service-daemon`):
  TensorBoard is a suite of web applications for inspecting and understanding your TensorFlow runs
  and graphs.
- [`vector`](./vector/README.md) (`T1` — `userland-package`, `service-daemon`): High-performance
  end-to-end observability data router and transformation pipeline built in Rust.

<!-- END_COMPONENTS -->
