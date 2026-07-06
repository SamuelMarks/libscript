# Valkey

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `valkey` component (part
of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**Valkey**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of Valkey, and it can be invoked seamlessly
from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this Valkey component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall valkey using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install valkey

./cli.sh install valkey

./libscript.sh start valkey
./cli.sh start valkey

./libscript.sh stop valkey
./cli.sh stop valkey

./libscript.sh package-as docker valkey
./cli.sh package-as docker valkey

./libscript.sh uninstall valkey
./cli.sh uninstall valkey
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install valkey

:: Local CLI
cli.cmd install valkey

:: Start and Stop
libscript.cmd start valkey
cli.cmd start valkey

libscript.cmd stop valkey
cli.cmd stop valkey

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi valkey
cli.cmd package-as msi valkey

:: Uninstall
libscript.cmd uninstall valkey
cli.cmd uninstall valkey
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
| `VALKEY_VERSION` | Specific version of Valkey to install | `latest` |  |
| `VALKEY_BUILD_DIR` | Directory to build valkey from | `none` |  |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `VALKEY_LISTEN_PORT` | Port for VALKEY to listen on | `none` |  |
| `VALKEY_LISTEN_ADDRESS` | Address for VALKEY to listen on | `none` |  |
| `VALKEY_LISTEN_SOCKET` | Unix socket for VALKEY to listen on | `none` |  |
| `VALKEY_DATA_DIR` | Directory for Valkey data | `none` |  |
| `VALKEY_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` |  |
| `VALKEY_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` |  |
| `VALKEY_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_valkey` |  |
| `VALKEY_INSTALL_METHOD` | How to install VALKEY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
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

Libscript manages valkey versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/valkey/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
