# Fluentbit

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `fluentbit` component
within the LibScript ecosystem. This component manages **Fluent Bit**, a super fast, lightweight,
and highly scalable logging and metrics processor and forwarder. It allows you to collect data/logs
from different sources, unify, and send them to multiple destinations. It's fully compatible with
Docker and Kubernetes environments.

## Usage

This directory contains the scripts to interact with `fluentbit`. It is designed to be executed via
the global `libscript` command or directly via local CLI scripts.

### Integration in `libscript`

This module provides setup, test, and uninstall capabilities for `fluent-bit`.

- **Windows Details**: On Windows, it installs via Chocolatey or falls back to natively downloading
  and extracting the official `.zip` archive from `packages.fluentbit.io`.
- **POSIX Details**: On Linux and macOS, it delegates to the system package manager (e.g.,
  `apt-get`, `brew`, `apk`) to install `fluent-bit`.

You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**

```sh
libscript install fluentbit
```

**Start:**

```sh
libscript start fluentbit
```

**Stop:**

```sh
libscript stop fluentbit
```

**Uninstall:**

```sh
libscript uninstall fluentbit
```

**Package:**

```sh
libscript package_as docker fluentbit

```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript-native). | `libscript-native` |  |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows (winget, choco). | `winget` |  |
| `LIBSCRIPT_LOG_LEVEL` | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR). | `1` |  |
| `LIBSCRIPT_LOG_FORMAT` | Output format for logs (text, json). | `text` |  |
| `LIBSCRIPT_LOG_FILE` | File to write logs to (in addition to standard output). | `none` |  |
| `LIBSCRIPT_SERVICE_NAME` | Overrides the default service name. | `none` |  |
| `DOWNLOAD_DIR` | Directory where downloads are stored. | `none` |  |
| `FORMAT` | Output format (e.g., json, text). | `none` |  |
| `LIBSCRIPT_CACHE_DIR` | Directory where cached files are stored. | `none` |  |
| `LIBSCRIPT_LOG_DRIVER` | Logging driver to use (e.g., fluentd). | `none` |  |
| `LOGS_DIR` | Directory where logs should be stored. | `none` |  |
| `VAULT_TOKEN` | Token for HashiCorp Vault authentication. | `none` |  |
| `PREFIX` | Installation prefix. | `none` |  |
| `SERVE_FROM` | Base directory or context path for the service. | `none` |  |
| `LIBSCRIPT_LOG_HOST` | Host for remote logging. | `none` |  |
| `LIBSCRIPT_VERSION` | Specifies the version of the package to use. | `none` |  |
| `LIBSCRIPT_LOG_PORT` | Port for remote logging. | `none` |  |
| `TPU_ZONE` | GCP Zone for TPU provisioning | `us-central2-b` |  |
| `TPU_ACCELERATOR_TYPE` | Type of TPU accelerator (e.g. v4-8) | `v4-8` |  |
| `TPU_VERSION` | TPU VM OS version | `tpu-ubuntu2204-base` |  |
| `GCP_PROJECT_ID` | GCP Project ID | `none` |  |
| `XPK_CLUSTER_NAME` | Name for the XPK GKE cluster | `none` |  |
| `TPU_TENSOR_PARALLEL_SIZE` | Tensor parallel size for TPU serving | `1` |  |
| `MODEL_NAME` | HuggingFace model string to serve | `your-org/your-model-name` |  |
| `WORKLOAD_NAME` | Name of the XPK workload | `none` |  |
| `JETSTREAM_IMAGE` | Docker image for JetStream TPU inference | `none` |  |
| `FLUENTBIT_VERSION` | Specific version of Fluent Bit to install. Can be a numeric version (e.g. '3.0.0') or an alias like 'latest'. | `latest` | latest, stable |
| `FLUENTBIT_INSTALL_METHOD` | How to install FLUENTBIT. 'libscript-native' uses isolated version dirs, 'system' uses OS package manager, 'mise' or 'asdf' defers to third-party tools. | `libscript-native` |  |
| `FLUENTBIT_CONFIG_FILE` | Absolute path to a pre-existing custom fluent-bit.conf file to use instead of the default configuration. | `none` |  |
| `FLUENTBIT_LOG_LEVEL` | The logging verbosity level for the Fluent Bit daemon itself (e.g. info, debug, error). | `info` |  |
| `FLUENTBIT_HTTP_SERVER` | Enable the built-in HTTP server for metrics and health checks. Highly recommended for monitoring. | `On` |  |
| `FLUENTBIT_LISTEN_PORT` | Port for the Fluent Bit HTTP metrics interface to listen on. | `2020` |  |
| `FLUENTBIT_LISTEN_ADDRESS` | Address for the Fluent Bit HTTP metrics interface to bind to. | `0.0.0.0` |  |
| `FLUENTBIT_LISTEN_SOCKET` | Optional: Unix socket for the Fluent Bit metrics interface to listen on (Linux/macOS only). | `none` |  |
| `FLUENTBIT_DEFAULT_INPUT` | Default input plugin to configure for collecting data (e.g. 'tail', 'forward', 'cpu', 'dummy'). | `dummy` |  |
| `FLUENTBIT_DEFAULT_OUTPUT` | Default output plugin to configure for routing data (e.g. 'stdout', 'es', 'loki', 'http'). | `stdout` |  |
| `FLUENTBIT_SERVICE_RUN_AS_USER` | Windows local user account to run the service under (leave empty to use Network Service / Local System). | `none` |  |
| `FLUENTBIT_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable). | `none` |  |
| `FLUENTBIT_SERVICE_NAME` | Custom name for the Fluent Bit background service (allows side-by-side installations). | `libscript_fluentbit` |  |
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
