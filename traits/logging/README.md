# Centralized Logging Trait (`traits/logging/`)

## Overview

`traits/logging/` queries installed components via `hooks/log_stream.{sh,cmd}` and renders
idempotent `[INPUT]` tail blocks and `[OUTPUT]` sinks (OpenSearch, Loki, syslog, S3) into
`_lib/logging/fluentbit/`.
