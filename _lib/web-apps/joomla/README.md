# Joomla

A generic setup script to deploy the [Joomla! CMS](https://www.joomla.org/) using LibScript.

## Features Supported

- Fully automated download and extraction of the latest (or specific) Joomla release.
- Web server integration: Nginx, Caddy, HTTPD (Apache), IIS (Windows).
- Database configuration: MariaDB/MySQL, PostgreSQL.

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
| `JOOMLA_VERSION`                   | Variable JOOMLA_VERSION.                                                                       | `none`                     |                  |
| `JOOMLA_DB_PASS`                   | Variable JOOMLA_DB_PASS.                                                                       | `none`                     |                  |
| `JOOMLA_PHP_FPM_LISTEN`            | Variable PHP_FPM_LISTEN.                                                                       | `none`                     |                  |
| `JOOMLA_LISTEN`                    | Variable JOOMLA_LISTEN.                                                                        | `none`                     |                  |
| `JOOMLA_DB_TYPE`                   | Variable JOOMLA_DB_TYPE.                                                                       | `none`                     |                  |
| `JOOMLA_WEBSERVER`                 | Variable JOOMLA_WEBSERVER.                                                                     | `none`                     |                  |
| `JOOMLA_WWWROOT`                   | Variable WWWROOT.                                                                              | `none`                     |                  |
| `JOOMLA_DB_USER`                   | Variable JOOMLA_DB_USER.                                                                       | `none`                     |                  |
| `JOOMLA_SERVER_NAME`               | Variable JOOMLA_SERVER_NAME.                                                                   | `none`                     |                  |
| `JOOMLA_DB_NAME`                   | Variable JOOMLA_DB_NAME.                                                                       | `none`                     |                  |

<!-- END_VARS -->

## Example Usage

### Linux / macOS (Nginx + MariaDB)

```sh
export JOOMLA_WEBSERVER="nginx"
export JOOMLA_DB_TYPE="mariadb"
export JOOMLA_VERSION="latest"
./setup.sh
```

### Windows (IIS + PostgreSQL)

```cmd
set JOOMLA_WEBSERVER=iis
set JOOMLA_DB_TYPE=postgres
set JOOMLA_VERSION=5.2.0
setup.cmd
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/php`: PHP runtime and database drivers
- `_lib/databases/mariadb` (or `postgres`): Relational database storage
- `_lib/web-servers/nginx` (or `caddy`, `httpd`, `iis`): Web server
