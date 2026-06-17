# Python Server

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `python` server component
within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script framework
designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the scripts for managing the Python server component. It works both as a
local version manager (similar to rvm, nvm, pyenv, uv) for precise Python version control, and can
be invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open
edX, nextcloud, etc.), serving as a robust foundation for multi-tier architectures.

You can install, start, stop, package, and uninstall python-server using the global `libscript`
command or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install python

./cli.sh install python

./libscript.sh start python
./cli.sh start python

./libscript.sh stop python
./cli.sh stop python

./libscript.sh package_as docker python
./cli.sh package_as docker python

./libscript.sh uninstall python
./cli.sh uninstall python
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install python

:: Local CLI
cli.cmd install python

:: Start and Stop
libscript.cmd start python
cli.cmd start python

libscript.cmd stop python
cli.cmd stop python

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi python
cli.cmd package_as msi python

:: Uninstall
libscript.cmd uninstall python
cli.cmd uninstall python
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
| `PYTHON_SERVER_DEST` | Destination (working directory) | `none` |  |
| `PYTHON_SERVER_VARS` | Key/value in JSON format (as an escaped string) | `none` |  |
| `PYTHON_SERVER_VENV` | Path to a Python virtualenv | `none` |  |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `PYTHON_SERVER_LISTEN_PORT` | Port for PYTHON to listen on | `none` |  |
| `PYTHON_SERVER_LISTEN_ADDRESS` | Address for PYTHON to listen on | `none` |  |
| `PYTHON_SERVER_LISTEN_SOCKET` | Unix socket for PYTHON to listen on | `none` |  |
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
