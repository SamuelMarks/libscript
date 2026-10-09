# Odoo

## Usage

This document describes the `Odoo` component within the LibScript ecosystem. This module installs
Odoo alongside a webserver and a database (typically PostgreSQL).

It works both as a local version manager and can be invoked from the global version manager
`libscript`. Furthermore, this component can be used by libscript to build bigger stacks by
composing it with caching layers, load balancers, or other services.

You can manage Odoo using the global `libscript` CLI or local scripts.

- **Install:** `libscript install odoo`
- **Uninstall:** `libscript uninstall odoo`
- **Start:** `libscript start odoo`
- **Stop:** `libscript stop odoo`
- **Package:** `libscript package-as docker odoo` (or `msi`, `docker_compose`, etc.)

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                    | Default                    | Aliases/Examples |
| ---------------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).             | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                   | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                           | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                           | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                        | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                            | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                          | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                              | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                       | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.   | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted. | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                            | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                         | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                         | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                      | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                           | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                       | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                   | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                       | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                  | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                            | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                              | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                 | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                   | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                           | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                              | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                       | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                       | `none`                     |                  |
| `ODOO_DB_TYPE`                     | Variable ODOO_DB_TYPE.                                                                         | `none`                     |                  |
| `ODOO_LISTEN`                      | Variable ODOO_LISTEN.                                                                          | `none`                     |                  |
| `ODOO_VERSION`                     | Variable ODOO_VERSION.                                                                         | `none`                     |                  |
| `ODOO_DB_USER`                     | Variable ODOO_DB_USER.                                                                         | `none`                     |                  |
| `ODOO_DB_HOST`                     | Variable ODOO_DB_HOST.                                                                         | `none`                     |                  |
| `ODOO_WEBSERVER`                   | Variable ODOO_WEBSERVER.                                                                       | `none`                     |                  |
| `ODOO_WWWROOT`                     | Variable WWWROOT.                                                                              | `none`                     |                  |
| `ODOO_SERVER_NAME`                 | Variable ODOO_SERVER_NAME.                                                                     | `none`                     |                  |
| `ODOO_DB_NAME`                     | Variable ODOO_DB_NAME.                                                                         | `none`                     |                  |
| `ODOO_DB_PASS`                     | Variable ODOO_DB_PASS.                                                                         | `none`                     |                  |
| `ODOO_DB_PORT`                     | Variable ODOO_DB_PORT.                                                                         | `none`                     |                  |
| `ODOO_PORT`                        | Variable ODOO_PORT.                                                                            | `none`                     |                  |
| `db_strategy`                      | Database provisioning strategy (e.g. relational vs nosql).                                     | `local`                    |                  |
| `db_host`                          | Database connection host.                                                                      | `127.0.0.1`                |                  |
| `db_name`                          | Database name.                                                                                 | `odoo`                     |                  |
| `db_url`                           | Full database connection string or URL.                                                        | `none`                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/python`: Python runtime and Odoo application framework
- `_lib/databases/postgres`: PostgreSQL database server
- `_lib/web-servers/nginx` (or `caddy`, `httpd`): Reverse proxy and static file server
