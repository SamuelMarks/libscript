# C11 REST API Server Source (`libscript-rest-api/src/`)

## Overview

`libscript-rest-api/src/` contains the strict C11 implementation of the `Plane B` LibScript HTTP
control-plane daemon built atop `c-rest-framework` and conforming to
[`../openapi.yaml`](../openapi.yaml) (OpenAPI 3.2.0).

## Source Files

- **`CMakeLists.txt`**: Target compilation rules, C11 standard flags, and `c-rest-framework`
  linkage.
- **`rest_api.h`**: Public request/response structures, route registration declarations, and command
  dispatch interfaces.
- **`main.c`**: Daemon entry point, CLI flag/environment parsing, socket binding, and graceful
  signal shutdown lifecycle.
- **`rest_dispatch.c`**: Maps authenticated HTTP endpoints (`/components`, `/stacks`, `/clusters`,
  `/constellations`, `/payloads`, `/traits`, `/health`) to non-shell-interpolated `libscript`
  subprocess executions with structured JSON output framing.
