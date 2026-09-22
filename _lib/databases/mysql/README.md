# MySQL

MySQL 8.x relational database management system.

## Usage

Provides `mysql` server and client for database workloads. Open edX uses MySQL 8.x (with `utf8mb4`
collation) as its primary relational store for LMS and CMS data.

```sh
./libscript.sh install mysql
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                       | Default                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                      | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                              | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                              | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                           | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                               | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                             | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                      | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                    | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                               | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                            | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                            | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                         | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                              | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                   | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                      | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                          | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                     | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                               | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                 | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                    | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                      | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                              | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                 | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                          | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                          | `none`                     |                  |
| `MYSQL_VERSION`                    | Specific version of MySQL to install (e.g. '8.4.11', '8.0.36', 'latest').                                                                         | `8.4.11`                   |                  |
| `MYSQL_INSTALL_METHOD`             | Installation method for MySQL ('system', 'libscript_native').                                                                                     | `system`                   |                  |
| `MYSQL_PORT`                       | TCP port MySQL listens on.                                                                                                                        | `3306`                     |                  |
| `MYSQL_ROOT_PASSWORD`              | Root password for MySQL server administration.                                                                                                    | ``                         |                  |
| `MYSQL_DATABASE`                   | Initial database to create upon setup (e.g., 'openedx').                                                                                          | `openedx`                  |                  |
| `MYSQL_USER`                       | Database user account to create and grant permissions.                                                                                            | `openedx`                  |                  |
| `MYSQL_PASSWORD`                   | Password for the database user account.                                                                                                           | ``                         |                  |
| `MYSQL_DATA_DIR`                   | Custom directory where MySQL storage engine databases are kept.                                                                                   | `none`                     |                  |
| `MYSQL_REMOTE_URL`                 | Connection string or URL for external MySQL host (e.g. 'mysql://user:pass@remote-host:3306/db'). If set, local MySQL installation can be skipped. | `none`                     |                  |
| `MYSQL_INSTALL_LOCAL`              | Whether to install and provision a local MySQL database server instance.                                                                          | `true`                     |                  |
| `MYSQL_SKIP_LOCAL_INSTALL`         | Explicitly bypass local MySQL server setup when utilizing a managed remote database.                                                              | `none`                     |                  |
| `MYSQL_CHARACTER_SET`              | Default server and database character set.                                                                                                        | `utf8mb4`                  |                  |
| `MYSQL_COLLATION`                  | Default server and database collation sequence.                                                                                                   | `utf8mb4_unicode_ci`       |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
