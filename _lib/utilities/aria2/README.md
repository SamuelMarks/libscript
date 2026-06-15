# aria2

Provides lightweight utility wrappers for the `aria2` multi-protocol download utility, heavily
utilized by the package management layer for parallelized fetching.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                              | Default  | Aliases/Examples |
| --------------------------------- | ------------------------------------------------------------------------ | -------- | ---------------- |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed (system vs source). | `system` |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`       | Global package manager override for Windows (winget, choco).             | `winget` |                  |
| `LIBSCRIPT_LOG_LEVEL`             | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).     | `1`      |                  |
| `LIBSCRIPT_LOG_FORMAT`            | Output format for logs (text, json).                                     | `text`   |                  |
| `LIBSCRIPT_LOG_FILE`              | File to write logs to (in addition to standard output).                  | `none`   |                  |
| `LIBSCRIPT_SERVICE_NAME`          | Overrides the default service name.                                      | `none`   |                  |
| `DOWNLOAD_DIR`                    | Directory where downloads are stored.                                    | `none`   |                  |
| `FORMAT`                          | Output format (e.g., json, text).                                        | `none`   |                  |
| `LIBSCRIPT_CACHE_DIR`             | Directory where cached files are stored.                                 | `none`   |                  |
| `LIBSCRIPT_LOG_DRIVER`            | Logging driver to use (e.g., fluentd).                                   | `none`   |                  |
| `LOGS_DIR`                        | Directory where logs should be stored.                                   | `none`   |                  |
| `VAULT_TOKEN`                     | Token for HashiCorp Vault authentication.                                | `none`   |                  |
| `PREFIX`                          | Installation prefix.                                                     | `none`   |                  |
| `SERVE_FROM`                      | Base directory or context path for the service.                          | `none`   |                  |
| `LIBSCRIPT_LOG_HOST`              | Host for remote logging.                                                 | `none`   |                  |
| `LIBSCRIPT_VERSION`               | Specifies the version of the package to use.                             | `none`   |                  |
| `LIBSCRIPT_LOG_PORT`              | Port for remote logging.                                                 | `none`   |                  |
| `ARIA2_VERSION`                   | Specific version of aria2 to install.                                    | `latest` |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
