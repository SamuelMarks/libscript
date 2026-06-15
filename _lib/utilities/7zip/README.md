# 7-Zip

## Usage

This document describes **7zip (7-Zip)**, a highly efficient, open-source file archiver known for
its high compression ratio and wide format support.

7zip works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. It acts as an essential foundational tool and can be used by
libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) that require archive
extraction or compression.

You can install, start, stop, package, and uninstall 7zip using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install 7zip

./cli.sh install 7zip

./libscript.sh start 7zip
./cli.sh start 7zip

./libscript.sh stop 7zip
./cli.sh stop 7zip

./libscript.sh package_as docker 7zip
./cli.sh package_as docker 7zip

./libscript.sh uninstall 7zip
./cli.sh uninstall 7zip
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install 7zip

:: Local CLI
cli.cmd install 7zip

:: Start and Stop
libscript.cmd start 7zip
cli.cmd start 7zip

libscript.cmd stop 7zip
cli.cmd stop 7zip

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi 7zip
cli.cmd package_as msi 7zip

:: Uninstall
libscript.cmd uninstall 7zip
cli.cmd uninstall 7zip
```

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
| `7ZIP_VERSION`                    | Specific version of 7zip to install.                                     | `latest` |                  |

<!-- END_VARS -->

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
