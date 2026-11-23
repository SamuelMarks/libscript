# Plane A Telemetry & Metrics Scraping Trait (`traits/metrics/`)

## Overview

`traits/metrics/` wires host hardware telemetry and `T1` component `hooks/metrics.{sh,cmd}`
exporters into unified Prometheus or OpenTelemetry scrape configurations.

## Scripts

- **`agent.{sh,cmd}`**: Configures Prometheus Node Exporter, Windows Exporter, or OpenTelemetry
  Collector (`otelcol`) scrape targets and remote-write pipelines in both `T3` `--sysroot` bake mode
  and live `T4`/`T5` runtime mode.

## Usage

```sh
./libscript.sh trait apply metrics
./libscript.sh trait verify metrics
```
