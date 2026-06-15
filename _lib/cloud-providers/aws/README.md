# Amazon Web Services (AWS)

This module configures the `aws` cloud provider capabilities within LibScript. It leverages the AWS
CLI and associated tools to provide provisioning and configuration targets for Amazon Web Services.

## Purpose & Current State

- Provides runtime context and authentication pathways for AWS targets.
- Serves as the foundation for multi-cloud deployments bridging to EC2, EKS, and S3 resources.

## Usage

Used internally by the `libscript deploy` and `libscript teardown` systems when AWS is the target
provider.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                          | Description                                                              | Default     | Aliases/Examples |
| --------------------------------- | ------------------------------------------------------------------------ | ----------- | ---------------- |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed (system vs source). | `system`    |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`       | Global package manager override for Windows (winget, choco).             | `winget`    |                  |
| `LIBSCRIPT_LOG_LEVEL`             | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).     | `1`         |                  |
| `LIBSCRIPT_LOG_FORMAT`            | Output format for logs (text, json).                                     | `text`      |                  |
| `LIBSCRIPT_LOG_FILE`              | File to write logs to (in addition to standard output).                  | `none`      |                  |
| `LIBSCRIPT_SERVICE_NAME`          | Overrides the default service name.                                      | `none`      |                  |
| `DOWNLOAD_DIR`                    | Directory where downloads are stored.                                    | `none`      |                  |
| `FORMAT`                          | Output format (e.g., json, text).                                        | `none`      |                  |
| `LIBSCRIPT_CACHE_DIR`             | Directory where cached files are stored.                                 | `none`      |                  |
| `LIBSCRIPT_LOG_DRIVER`            | Logging driver to use (e.g., fluentd).                                   | `none`      |                  |
| `LOGS_DIR`                        | Directory where logs should be stored.                                   | `none`      |                  |
| `VAULT_TOKEN`                     | Token for HashiCorp Vault authentication.                                | `none`      |                  |
| `PREFIX`                          | Installation prefix.                                                     | `none`      |                  |
| `SERVE_FROM`                      | Base directory or context path for the service.                          | `none`      |                  |
| `LIBSCRIPT_LOG_HOST`              | Host for remote logging.                                                 | `none`      |                  |
| `LIBSCRIPT_VERSION`               | Specifies the version of the package to use.                             | `none`      |                  |
| `LIBSCRIPT_LOG_PORT`              | Port for remote logging.                                                 | `none`      |                  |
| `AWS_DEFAULT_REGION`              | MISSING DESCRIPTION                                                      | `us-east-1` |                  |
| `AWS_ACCESS_KEY_ID`               | MISSING DESCRIPTION                                                      | `none`      |                  |
| `AWS_SECRET_ACCESS_KEY`           | MISSING DESCRIPTION                                                      | `none`      |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
