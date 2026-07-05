# Docker

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `docker` component (part
of `_server`) within the LibScript ecolibscript_native. Docker is a platform for developing,
shipping, and running containerized applications.

## Usage

This directory contains the installation and configuration scripts for `docker`. This component
works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the
global version manager `libscript`.

Furthermore, Docker can be used by libscript to build bigger stacks (like WordPress, Open edX,
Nextcloud, etc.) by providing the underlying containerization runtime.

You can install, start, stop, package, and uninstall docker using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install docker

./cli.sh install docker

./libscript.sh start docker
./cli.sh start docker

./libscript.sh stop docker
./cli.sh stop docker

./libscript.sh package-as docker docker
./cli.sh package-as docker docker

./libscript.sh uninstall docker
./cli.sh uninstall docker
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install docker

:: Local CLI
cli.cmd install docker

:: Start and Stop
libscript.cmd start docker
cli.cmd start docker

libscript.cmd stop docker
cli.cmd stop docker

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi docker
cli.cmd package-as msi docker

:: Uninstall
libscript.cmd uninstall docker
cli.cmd uninstall docker
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native). | `libscript_native` |  |
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
| `DOCKER_VERSION` | Specific version of docker to install. Can be a numeric version or an alias. | `latest` | latest, stable |
| `DOCKER_INSTALL_METHOD` | How to install DOCKER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `DOCKER_LISTEN_PORT` | Port for DOCKER to listen on | `none` |  |
| `DOCKER_LISTEN_ADDRESS` | Address for DOCKER to listen on | `none` |  |
| `DOCKER_LISTEN_SOCKET` | Unix socket for DOCKER to listen on | `none` |  |
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

Libscript manages docker versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/docker/<version>`.
