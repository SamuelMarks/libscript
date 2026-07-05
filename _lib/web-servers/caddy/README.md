# Caddy

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `caddy` server component
within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the scripts for managing the Caddy component. It works both as a local
version manager (similar to rvm, nvm, pyenv, uv) for precise Caddy version control, and can be
invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open
edX, nextcloud, etc.), easily providing automatic HTTPS and web server functionality.

You can manage the lifecycle of this component using the global `libscript` command or the local
CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install caddy

./cli.sh install caddy

./libscript.sh start caddy
./cli.sh start caddy

./libscript.sh stop caddy
./cli.sh stop caddy

./libscript.sh package-as docker caddy
./cli.sh package-as docker caddy

./libscript.sh uninstall caddy
./cli.sh uninstall caddy
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install caddy

:: Local CLI
cli.cmd install caddy

:: Start and Stop
libscript.cmd start caddy
cli.cmd start caddy

libscript.cmd stop caddy
cli.cmd stop caddy

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi caddy
cli.cmd package-as msi caddy

:: Uninstall
libscript.cmd uninstall caddy
cli.cmd uninstall caddy
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
| `CADDY_INSTALL_METHOD` | How to install CADDY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
| `CADDY_VERSION` | Specific version of caddy to install. Can be a numeric version or an alias. | `latest` | latest, stable |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` |  |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` |  |
| `CADDY_LISTEN_PORT` | Port for CADDY to listen on | `none` |  |
| `CADDY_LISTEN_ADDRESS` | Address for CADDY to listen on | `none` |  |
| `CADDY_LISTEN_SOCKET` | Unix socket for CADDY to listen on | `none` |  |
| `CADDY_WWWROOT_NAME` | The primary domain or server name (e.g., example.com) to bind the web server to. | `none` |  |
| `CADDY_WWWROOT_PATH` | The absolute path to the static site document root (where index.html resides). | `none` |  |
| `CADDY_WWWROOT_LISTEN` | The HTTP port Caddy should listen on (defaults to 80, but 443 is used automatically for HTTPS). | `80` |  |
| `CADDY_WWWROOT_HTTPS_PROVIDER` | The HTTPS provider for automatic certificates. Usually 'letsencrypt' or 'zerossl' (Caddy uses both by default if not set). | `none` |  |
| `CADDY_SERVICE_RUN_AS_USER` | Windows local user account to run the service under (leave empty for Network Service). | `none` |  |
| `CADDY_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable). | `none` |  |
| `CADDY_SERVICE_NAME` | Custom name for the Windows Service (allows side-by-side installations). | `libscript_caddy` |  |
| `CADDY_LISTEN` | Address/port to listen on. | `none` |  |
| `CADDY_WWWROOT` | Web server root directory. | `none` |  |
| `CADDY_PHP_FPM_LISTEN` | Listen address/socket for PHP-FPM. | `none` |  |
| `CADDY_SERVER_NAME` | Name of the server (e.g., example.com). | `none` |  |
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

Libscript manages caddy versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/caddy/<version>`.
