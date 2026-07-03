# Systemd

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `systemd` component (part
of `_daemon`) within the LibScript ecosystem. This component configures and manages systemd unit
files, enabling applications to run as standard background services on compatible Linux
distributions.

## Usage

This directory contains the installation and configuration scripts for `systemd`. This component
works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the
global version manager `libscript`.

Furthermore, systemd integrations can be used by libscript to build bigger stacks (like WordPress,
Open edX, Nextcloud, etc.) by ensuring system processes are monitored, restarted on failure, and
initiated at boot.

You can install, start, stop, package, and uninstall systemd using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install systemd

./cli.sh install systemd

./libscript.sh start systemd
./cli.sh start systemd

./libscript.sh stop systemd
./cli.sh stop systemd

./libscript.sh package_as docker systemd
./cli.sh package_as docker systemd

./libscript.sh uninstall systemd
./cli.sh uninstall systemd
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install systemd

:: Local CLI
cli.cmd install systemd

:: Start and Stop
libscript.cmd start systemd
cli.cmd start systemd

libscript.cmd stop systemd
cli.cmd stop systemd

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi systemd
cli.cmd package_as msi systemd

:: Uninstall
libscript.cmd uninstall systemd
cli.cmd uninstall systemd
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
| `SYSTEMD_EXEC_START` | Executor | `none` |  |
| `SYSTEMD_WORKING_DIR` | Working directory that `EXEC_START` will be run from | `none` |  |
| `SYSTEMD_ENV` | Optional additional properties as key/value pairs | `none` |  |
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
