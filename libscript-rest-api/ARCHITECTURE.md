# Architecture

The `libscript-rest-api` is designed as a lightweight, C-based daemon. Its primary responsibility is
to act as a secure, asynchronous HTTP bridge to the underlying `libscript` shell execution
environment.

## Core Components

### 1. HTTP Daemon (`c-rest-framework`)

The core HTTP server handles incoming requests, TLS termination (if configured), CORS, and route
multiplexing. It parses incoming JSON payloads and serializes C structs back into JSON responses.

### 2. Middleware & Security Layer

Before any request reaches a handler, it passes through:

- **Authentication:** Validates Bearer tokens or API keys if `AUTH_ENABLED=true`.
- **Schema Validation:** Ensures incoming JSON matches predefined OpenAPI schemas to prevent
  malformed data from reaching the execution layer.

### 3. Shell Execution Wrapper

A safe abstraction over `fork()` and `exec()`. It guarantees:

- **Sanitization:** Input variables are rigorously sanitized to prevent shell injection
  vulnerabilities.
- **Environment Isolation:** Scripts are run with a controlled set of environment variables.
- **I/O Capture:** `stdout` and `stderr` are piped and captured for logging and job querying.

### 4. Job Manager

Many `libscript` tasks (like provisioning resources) are long-running. The Job Manager:

- Forks detached processes for background execution.
- Generates a unique `job_id` (UUID).
- Tracks the PID and log output locations.
- Provides status updates via the `/api/v1/jobs/{job_id}` endpoint.

### 5. Configuration & State

- **Configuration:** Loaded at startup via `.env` files or environment variables.
- **State:** Reads `libscript` manifests and local state files (e.g., in `/var/lib/libscript` or
  `~/.local/state/libscript`) to list installed components and active resources.
