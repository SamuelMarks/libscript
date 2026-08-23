# Apache HTTPD

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `httpd` server component
within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the scripts for managing the Apache HTTPD component. It works both as a
local version manager (similar to rvm, nvm, pyenv, uv) for precise HTTPD version control, and can be
invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open
edX, nextcloud, etc.), serving as a reliable web server foundation.

You can install, start, stop, package, and uninstall httpd using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install httpd

./cli.sh install httpd

./libscript.sh start httpd
./cli.sh start httpd

./libscript.sh stop httpd
./cli.sh stop httpd

./libscript.sh package-as docker httpd
./cli.sh package-as docker httpd

./libscript.sh uninstall httpd
./cli.sh uninstall httpd
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install httpd

:: Local CLI
cli.cmd install httpd

:: Start and Stop
libscript.cmd start httpd
cli.cmd start httpd

libscript.cmd stop httpd
cli.cmd stop httpd

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi httpd
cli.cmd package-as msi httpd

:: Uninstall
libscript.cmd uninstall httpd
cli.cmd uninstall httpd
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
| `HTTPD_INSTALL_METHOD` | How to install HTTPD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |  |
| `HTTPD_VERSION` | Specific version of httpd to install. Can be a numeric version or an alias. | `latest` | latest, stable |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `HTTPD_LISTEN_PORT` | Port for HTTPD to listen on | `none` |  |
| `HTTPD_LISTEN_ADDRESS` | Address for HTTPD to listen on | `none` |  |
| `HTTPD_LISTEN_SOCKET` | Unix socket for HTTPD to listen on | `none` |  |
| `HTTPD_WWWROOT_NAME` | The primary domain or server name (ServerName) for Apache to bind to. | `none` |  |
| `HTTPD_WWWROOT_PATH` | The absolute path to the DocumentRoot directory. | `none` |  |
| `HTTPD_WWWROOT_LISTEN` | The HTTP port Apache should listen on (defaults to 80). | `80` |  |
| `HTTPD_SERVICE_RUN_AS_USER` | Windows local user account to run the Apache service under (leave empty for default). | `none` |  |
| `HTTPD_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable). | `none` |  |
| `HTTPD_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations). | `libscript_httpd` |  |
| `HTTPD_LISTEN` | Address/port to listen on. | `none` |  |
| `HTTPD_WWWROOT` | Web server root directory. | `none` |  |
| `HTTPD_PHP_FPM_LISTEN` | Listen address/socket for PHP-FPM. | `none` |  |
| `HTTPD_SERVER_NAME` | Name of the server (e.g., example.com). | `none` |  |
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
