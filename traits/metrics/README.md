# Metrics & Telemetry Trait (`traits/metrics/`)

## Overview

`traits/metrics/` queries installed components via `hooks/metrics.{sh,cmd}` (plus
`_lib/logging/tensorboard` for AI workloads) and emits atomic Prometheus `file_sd_configs` JSON
files (`/etc/prometheus/file_sd/*.json`).
