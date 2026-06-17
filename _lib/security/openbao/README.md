# Openbao

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openbao` component (part
of `_server`) within the LibScript ecosystem. OpenBao is an open-source tool for managing secrets
and protecting sensitive data.

## Usage

This directory contains the installation and configuration scripts for `openbao`. This component
works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the
global version manager `libscript`.

Furthermore, OpenBao can be used by libscript to build bigger stacks (like WordPress, Open edX,
Nextcloud, etc.) by providing secure secrets management to these applications.

### Usage with LibScript

You can easily manage the lifecycle of OpenBao using the global `libscript` command or the local
CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install openbao

./cli.sh install openbao

./libscript.sh start openbao
./cli.sh start openbao

./libscript.sh stop openbao
./cli.sh stop openbao

./libscript.sh package_as docker openbao
./cli.sh package_as docker openbao

./libscript.sh uninstall openbao
./cli.sh uninstall openbao
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install openbao

:: Local CLI
cli.cmd install openbao

:: Start and Stop
libscript.cmd start openbao
cli.cmd start openbao

libscript.cmd stop openbao
cli.cmd stop openbao

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi openbao
cli.cmd package_as msi openbao

:: Uninstall
libscript.cmd uninstall openbao
cli.cmd uninstall openbao
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed (system vs source). | `system` |  |
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
| `OPENBAO_VERSION` | Specific version of openbao to install. Can be a numeric version or an alias. | `latest` | latest, stable |
| `OPENBAO_INSTALL_METHOD` | How to install OPENBAO. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` |  |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `OPENBAO_LISTEN_PORT` | Port for OPENBAO to listen on | `none` |  |
| `OPENBAO_LISTEN_ADDRESS` | Address for OPENBAO to listen on | `none` |  |
| `OPENBAO_LISTEN_SOCKET` | Unix socket for OPENBAO to listen on | `none` |  |
| `OPENBAO_SERVICE_RUN_AS_USER` | Windows local user account to run the service under (leave empty for Network Service). | `none` |  |
| `OPENBAO_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable). | `none` |  |
| `OPENBAO_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations). | `libscript_openbao` |  |
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
