# PostgreSQL

## Purpose & Current State

This document provides context and technical details for the **PostgreSQL** component (part of the
`_storage` directory) within the LibScript ecolibscript_native. PostgreSQL is a powerful,
open-source object-relational database libscript_native.

This module works both as a local version manager for PostgreSQL (similar to `rvm`, `nvm`, `pyenv`,
or `uv`) and can be directly invoked from the global version manager `libscript`. Because of this
flexibility, PostgreSQL can be utilized by LibScript to provision and build bigger, more complex
software stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage

You can install, start, stop, package, and uninstall postgres using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install postgres

./cli.sh install postgres

./libscript.sh start postgres
./cli.sh start postgres

./libscript.sh stop postgres
./cli.sh stop postgres

./libscript.sh package-as docker postgres
./cli.sh package-as docker postgres

./libscript.sh uninstall postgres
./cli.sh uninstall postgres
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install postgres

:: Local CLI
cli.cmd install postgres

:: Start and Stop
libscript.cmd start postgres
cli.cmd start postgres

libscript.cmd stop postgres
cli.cmd stop postgres

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi postgres
cli.cmd package-as msi postgres

:: Uninstall
libscript.cmd uninstall postgres
cli.cmd uninstall postgres
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
| `POSTGRES_VERSION` | Version of PostgreSQL demanded | `none` |  |
| `POSTGRES_USER` | Username to create inside postgres | `none` |  |
| `POSTGRES_PASSWORD` | Password for created user inside postgres | `none` |  |
| `POSTGRES_PASSWORD_FILE` | Password file, its contents used as password for created user inside postgres | `none` |  |
| `POSTGRES_SERVICE_USER` | Username for superuser & system role | `none` |  |
| `POSTGRES_SERVICE_PASSWORD` | Password for postgres user; fallsback to `POSTGRES_PASSWORD` | `none` |  |
| `POSTGRES_HOST` | Hostname to serve postgres from | `none` |  |
| `POSTGRES_DB` | Database to create within postgres | `none` |  |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `POSTGRES_LISTEN_PORT` | Port for POSTGRES to listen on | `none` |  |
| `POSTGRES_LISTEN_ADDRESS` | Address for POSTGRES to listen on | `none` |  |
| `POSTGRES_LISTEN_SOCKET` | Unix socket for POSTGRES to listen on | `none` |  |
| `POSTGRES_DATA_DIR` | Directory for PostgreSQL data cluster | `none` |  |
| `POSTGRES_LOCALE` | Locale for PostgreSQL initdb (e.g. English, United States) | `none` |  |
| `POSTGRES_SERVICE_RUN_AS_USER` | Windows local user account to run the service (leave empty for Network Service) | `none` |  |
| `POSTGRES_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable) | `none` |  |
| `POSTGRES_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations) | `libscript_postgres` |  |
| `POSTGRES_SERVICE_GROUP` | Group for PostgreSQL service. | `none` |  |
| `POSTGRES_URL_VERSION` | URL format version for PostgreSQL. | `none` |  |
| `POSTGRES_URL` | Connection URL for PostgreSQL. | `none` |  |
| `POSTGRES_INSTALL_METHOD` | How to install POSTGRES. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
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

Libscript manages postgres versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/postgres/<version>`.
