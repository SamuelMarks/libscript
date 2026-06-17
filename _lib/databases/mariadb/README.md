# MariaDB

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `mariadb` component (part
of `_storage`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**MariaDB**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of MariaDB, and it can be invoked
seamlessly from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this MariaDB component as a foundational database building
block to provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall mariadb using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

libscript install mariadb

libscript start mariadb
libscript stop mariadb

libscript package_as docker mariadb

libscript uninstall mariadb
```

**Windows:**

```cmd
:: Install
libscript.cmd install mariadb

:: Start and Stop
libscript.cmd start mariadb
libscript.cmd stop mariadb

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi mariadb

:: Uninstall
libscript.cmd uninstall mariadb
```

_Alternatively, you can execute these locally from within this directory using
`./cli.sh install mariadb` or `cli.cmd install mariadb`._

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
| `MARIADB_VERSION` | Specific version of mariadb to install. Can be a numeric version or an alias. | `latest` | latest, stable |
| `MARIADB_INSTALL_METHOD` | How to install MARIADB. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` |  |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `MARIADB_LISTEN_PORT` | Port for MARIADB to listen on | `none` |  |
| `MARIADB_LISTEN_ADDRESS` | Address for MARIADB to listen on | `none` |  |
| `MARIADB_LISTEN_SOCKET` | Unix socket for MARIADB to listen on | `none` |  |
| `MARIADB_DATA_DIR` | Directory for MariaDB data | `none` |  |
| `MARIADB_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` |  |
| `MARIADB_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` |  |
| `MARIADB_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_mariadb` |  |
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
