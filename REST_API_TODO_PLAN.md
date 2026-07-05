# libscript REST API Implementation Plan

This document outlines the step-by-step plan for building the `libscript` REST API (located in the
`libscript-rest-api/` subdirectory) using the `c-rest-framework`.

## Phase 1: Bootstrapping & Environment Setup

- [ ] **Dependency Resolution Script**
  - [ ] Write a script to detect the host OS (Linux, macOS, Windows).
  - [ ] Add logic to install a C compiler (`gcc`, `clang`, or `cl` [MSVC] for Windows) via the
        system package manager or Visual Studio Build Tools.
  - [ ] Add logic to install `git`.
  - [ ] Add logic to install `cmake` and a build system (`make`, `ninja`, or MSBuild).
  - [ ] Add logic to install required C libraries (e.g., JSON parsers if not bundled with the
        framework).
- [ ] **Framework Acquisition**
  - [ ] Add a step to `git clone https://github.com/SamuelMarks/c-rest-framework` into a `vendor/`
        directory within `libscript-rest-api/`.
- [ ] **Build System Configuration**
  - [ ] Create the root `CMakeLists.txt` for the `libscript-rest-api` project in the new
        subdirectory.
  - [ ] Adhere to best practices: place source files (`.c`, `.h`) in a `src/` subdirectory and add a
        secondary `CMakeLists.txt` there.
  - [ ] Link the `c-rest-framework` and necessary system/OS-specific libraries within CMake.
  - [ ] Configure the build output directory (e.g., `build/`).
- [ ] **Initial Server Execution**
  - [ ] Write a minimal `main.c` (in `src/`) that starts the server on a default port (e.g., 8080).
  - [ ] Add a cross-platform command (like `cmake --build . --target run`) to compile and execute
        the server in one step.

## Phase 2: Core Architecture & Utilities

- [ ] **Configuration Management**
  - [ ] Implement parsing for configuration via environment variables or a `.env`/`.ini` file (e.g.,
        Host, Port, Log Level, Temp Dirs).
- [ ] **Application Logging**
  - [ ] Implement a standardized logging utility for request access logs and internal application
        tracing (Debug, Info, Warn, Error levels).
- [ ] **Graceful Shutdown**
  - [ ] Implement cross-platform signal handling (e.g., `SIGINT`/`SIGTERM` on POSIX, and
        `SetConsoleCtrlHandler` on Windows) to cleanly terminate running shell jobs and free
        allocated memory before exit.
- [ ] **Shell Execution Wrapper**
  - [ ] Implement a safe, cross-platform C function to execute `libscript` scripts (`fork`/`exec` on
        POSIX for `.sh`, and `CreateProcess` on Windows for `.cmd`/`.ps1`).
  - [ ] Ensure inputs are rigorously sanitized to prevent shell injection vulnerabilities.
  - [ ] Implement cross-platform stdout/stderr capture using pipes.
- [ ] **Asynchronous Job Management**
  - [ ] Design a simple tracking mechanism for background processes (e.g., storing PIDs/Process
        Handles and log file paths keyed by a UUID `job_id`).
  - [ ] Implement a function to spawn a detached process and return the `job_id`.
- [ ] **JSON Handling**
  - [ ] Integrate a C JSON library (like `cJSON` or `Jansson`).
  - [ ] Create helper functions for generating standard API error responses (400, 404, 500).

## Phase 3: Authentication & Authorization

- [ ] **Auth Configuration**
  - [ ] Implement a configuration flag (e.g., in a config file or environment variable) to toggle
        Auth. Default to `AUTH_ENABLED=false` (Single User Mode).
- [ ] **Middleware Implementation**
  - [ ] Create an auth middleware function that intercepts requests before they hit the route
        handlers.
  - [ ] If `AUTH_ENABLED=true`, validate a Bearer token or API key against a stored configuration.
  - [ ] Reject unauthorized requests with `401 Unauthorized`.
- [ ] **Security & Network Configuration**
  - [ ] Implement TLS/HTTPS support (either natively or document reverse-proxy termination setup).
  - [ ] Implement CORS (Cross-Origin Resource Sharing) middleware to allow web-based UI integration.
- [ ] **Authentication Endpoints**
  - [ ] `POST /api/v1/auth/token`: Implement OAuth2 Password Grant flow for token generation.
- [ ] **User Management Endpoints (Optional/Future)**
  - [ ] Design endpoints for basic user management if multi-user support is activated
        (`POST /api/v1/users`, etc.).

## Phase 4: OpenAPI Specification

- [ ] **Draft the OpenAPI YAML/JSON**
  - [ ] Create an `openapi.yaml` file describing the API surface area.
  - [ ] Define schemas for all request payloads and responses.
  - [ ] Define the security scheme (Bearer auth).
- [ ] **Input & Schema Validation**
  - [ ] Implement middleware or helper functions to enforce OpenAPI schemas on incoming JSON
        payloads _before_ they trigger script executions.
- [ ] **Integration with the Server**
  - [ ] Create an endpoint (e.g., `GET /api/v1/openapi.json`) that serves the specification.
  - [ ] (Optional) Bundle a tool like Swagger UI to serve the interactive documentation on
        `GET /docs`.

## Phase 5: API Endpoints Implementation

### System & Catalog

- [ ] `GET /api/v1/status`: Implement health check and basic OS info retrieval.
- [ ] `GET /api/v1/config`: Retrieve daemon configuration.
- [ ] `PUT /api/v1/config`: Update daemon configuration.
- [ ] `GET /api/v1/logs`: Retrieve daemon server logs.
- [ ] `POST /api/v1/downloads/process`: Implement wrapper around `process-downloads` to handle
      aria2-formatted download lists.
- [ ] `GET /api/v1/components`: Implement reading the local filesystem catalog to list available
      components.
- [ ] `POST /api/v1/registry/update`: Implement synchronizing the local catalog database
      (`registry update`).

### Stack & Dependency Resolution

- [ ] `POST /api/v1/stack/install`: Implement declarative stack deployment accepting a
      `libscript.json` payload (resolves deps and provisions).
- [ ] `POST /api/v1/stack/start`: Implement stack orchestration (daemonizing services, setting up
      ingress) from a `libscript.json` payload.

### Multicloud Resources & AI Orchestration

- [ ] `GET /api/v1/resources`: Implement parsing local state to list provisioned resources.
- [ ] `POST /api/v1/resources`: Implement endpoint to trigger background provisioning scripts;
      return `202` + `job_id`.
- [ ] `DELETE /api/v1/resources/{resource_id}`: Implement endpoint to trigger deprovisioning
      scripts; return `202` + `job_id`.
  - [ ] Implement query parameters `retain_ip` and `retain_data` to map to CLI flags (`--retain-ip`,
        `--retain-data`).
- [ ] `POST /api/v1/ai-stacks`: Implement deploying AI/ML hardware-accelerated stacks (e.g., TPU VM
      with vLLM/JetStream).

### Cloud Operations & Workload Management

- [ ] `DELETE /api/v1/cloud/resources`: Implement bulk cleanup logic across providers (maps to
      `libscript.sh cloud cleanup`); return `202` + `job_id`.
- [ ] `GET /api/v1/cloud/diff`: Implement comparison logic between local `.libscript_state.json` and
      provider remote state APIs (maps to `libscript.sh cloud diff`).
- [ ] `POST /api/v1/cloud/primitives/jumpbox`: Implement endpoint to directly provision jumpbox
      instances. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/primitives/node-group`: Implement endpoint to provision and bootstrap
      multi-node groups. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/primitives/network`: Implement endpoint for direct VPC/Subnet
      provisioning. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/primitives/firewall`: Implement endpoint to manage security
      groups/firewall rules. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/primitives/cron`: Implement endpoint to orchestrate distributed cloud cron
      jobs. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/nodes/{node_id}/deploy`: Implement `rsync`/tar-over-ssh deployment wrapper
      respecting `.gitignore`. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/nodes/{node_id}/scp`: Implement secure file transfer mechanism (handling
      multipart form data). Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/dns/map`: Implement cloud vendor DNS mapping wrappers (Route53, Cloud DNS,
      Azure DNS). Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/workloads/{node_id}/backup`: Implement orchestrating database quiesce
      hooks and pushing snapshot state to Object Storage/EBS. Return `202` + `job_id`.
- [ ] `POST /api/v1/cloud/workloads/restore`: Implement fetching backups and injecting state into
      target nodes (handling provider migrations if necessary). Return `202` + `job_id`.

### Component Installations

- [ ] `GET /api/v1/installations`: Implement scanning local manifests to list installed components.
- [ ] `GET /api/v1/installations/{component_id}`: Implement retrieving detailed component
      installation info (metadata, paths).
- [ ] `POST /api/v1/installations`: Implement endpoint to trigger `setup.sh`/`setup.cmd`; return
      `202` + `job_id`.
- [ ] `PUT /api/v1/installations/{component_id}`: Implement component upgrade logic.
- [ ] `DELETE /api/v1/installations/{component_id}`: Implement endpoint to trigger
      `uninstall.sh`/`uninstall.cmd`; return `202` + `job_id`.
- [ ] `GET /api/v1/installations/{component_id}/env`: Implement parsing and returning dynamic
      component output (e.g. credentials, `DATABASE_URL`).
  - [ ] Support a `format` query parameter to return output in various string formats (docker,
        docker_compose, powershell, cmd) instead of just a JSON map.
- [ ] `POST /api/v1/installations/{component_id}/invoke`: Implement arbitrary command execution
      (`run`, `exec`, custom commands) directed to the component's `cli.sh/cmd`. Return `202` +
      `job_id`.
- [ ] `POST /api/v1/installations/{component_id}/test`: Implement triggering native validation tests
      (`test.sh`/`test.cmd`).

### Artifact Generation

- [ ] `POST /api/v1/artifacts/generate`: Implement artifact factory endpoint utilizing `package-as`
      engine (e.g., Dockerfile, .deb, .msi); return `202` + `job_id`.
  - [ ] Support passing optional generator-specific flags via an `args` array in the request body.
- [ ] `GET /api/v1/artifacts/{artifact_id}/download`: Implement endpoint to stream the generated
      binary artifact.

### Daemon, Service & Network Control (netctl)

- [ ] `GET /api/v1/services/{component_id}`: Implement querying OS init systems (systemd, sysvinit,
      Windows Services) for service status.
- [ ] `GET /api/v1/services/{component_id}/logs`: Implement reading service runtime logs natively
      (e.g., streaming `journalctl -u <service>` or Get-EventLog).
- [ ] `POST /api/v1/services/{component_id}/daemonise`: Implement synchronous wrapper for
      `service_install.sh`/`service_install.cmd`.
- [ ] `POST /api/v1/services/{component_id}/dedaemonise`: Implement synchronous wrapper for service
      removal.
- [ ] `POST /api/v1/services/{component_id}/action`: Implement synchronous wrapper for
      start/stop/restart commands.
- [ ] `GET /api/v1/ingress/routes`: Implement fetching current reverse proxy routing configurations.
- [ ] `POST /api/v1/ingress/routes`: Implement adding application port mappings to domain names
      natively.
- [ ] `POST /api/v1/ingress/tls`: Implement Let's Encrypt certificate automation endpoint.

### Execution Tracking & Querying

- [ ] `GET /api/v1/jobs/{job_id}`: Implement endpoint to check process exit status and read log
      tails.
- [ ] `DELETE /api/v1/jobs/{job_id}`: Implement endpoint to cancel or forcibly terminate a running
      job.
- [ ] **Pagination & Filtering**: Implement limit/offset query parameters (e.g.,
      `?limit=50&offset=10`) for all `GET` list endpoints (components, resources, installations) to
      handle large result sets.

### Utilities

- [ ] `GET /api/v1/utils/semver`: Implement semantic versioning evaluation utility (maps to
      `libscript.sh semver`).

## Phase 6: Testing & Validation

- [ ] **Unit Tests**
  - [ ] Write tests for the JSON parsing and helper functions.
  - [ ] Write tests for the input sanitization logic.
- [ ] **Integration Tests**
  - [ ] Write cross-platform tests (e.g., in Python or using `curl` via bash/PowerShell) that hit
        the running API server.
  - [ ] Verify synchronous endpoints return expected data.
  - [ ] Verify asynchronous endpoints return a `job_id` and the background process executes
        correctly.
- [ ] **CI/CD Pipeline**
  - [ ] Create GitHub Actions workflows to automate building, linting, and testing the C code on
        push and PR across multiple OS matrices (Linux, macOS, Windows).
- [ ] **Documentation**
  - [ ] Update `libscript-rest-api/README.md` with instructions on how to build, run, and interact
        with the new API.

## Phase 7: Deployment & Containerization

- [ ] **Containerization**
  - [ ] Create `Dockerfile` wrappers (e.g., Alpine and Debian bases) for the compiled C API server.
  - [ ] Unify the container environment with the necessary shell utilities required by `libscript`.
        Unify the container environment with the necessary shell utilities required by `libscript`.
        containerization\*\*
  - [ ] Create `Dockerfile` wrappers (e.g., Alpine and Debian bases) for the compiled C API server.
  - [ ] Unify the container environment with the necessary shell utilities required by `libscript`.
