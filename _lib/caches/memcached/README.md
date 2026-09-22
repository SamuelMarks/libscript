# Memcached

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `memcached` component
(part of `_caches`) within the LibScript ecosystem. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**Memcached**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of Memcached, and it can be invoked
seamlessly from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this Memcached component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Django, Nextcloud, and more).

You can install, start, stop, package, and uninstall memcached using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh
./libscript.sh install memcached
./cli.sh install memcached

./libscript.sh start memcached
./cli.sh start memcached

./libscript.sh stop memcached
./cli.sh stop memcached

./libscript.sh package-as docker memcached
./cli.sh package-as docker memcached

./libscript.sh uninstall memcached
./cli.sh uninstall memcached
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install memcached

:: Local CLI
cli.cmd install memcached

:: Start and Stop
libscript.cmd start memcached
cli.cmd start memcached

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi memcached
cli.cmd package-as msi memcached

:: Uninstall
libscript.cmd uninstall memcached
cli.cmd uninstall memcached
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                               | Default                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                                        | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                                              | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                      | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                      | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                   | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                       | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                     | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                              | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                            | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                    | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                    | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                 | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                      | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                           | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                  | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                             | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                       | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                         | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                            | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                              | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                      | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                         | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                  | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                  | `none`                     |                  |
| `MEMCACHED_VERSION`                | Specific version of memcached to install. Can be a numeric version or an alias.                                                                                           | `latest`                   | latest, stable   |
| `MEMCACHED_INSTALL_METHOD`         | How to install MEMCACHED. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`         |                  |
| `LIBSCRIPT_LISTEN_PORT`            | Global port to listen on                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`         | Global address to listen on                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_LISTEN_SOCKET`          | Global unix socket to listen on                                                                                                                                           | `none`                     |                  |
| `MEMCACHED_LISTEN_PORT`            | Port for MEMCACHED to listen on                                                                                                                                           | `11211`                    |                  |
| `MEMCACHED_PORT_CONFLICT_POLICY`   | Policy if configured port is occupied: abort, auto-increment, or reuse                                                                                                    | `abort`                    |                  |
| `MEMCACHED_LISTEN_ADDRESS`         | Address for MEMCACHED to listen on                                                                                                                                        | `none`                     |                  |
| `MEMCACHED_LISTEN_SOCKET`          | Unix socket for MEMCACHED to listen on                                                                                                                                    | `none`                     |                  |
| `MEMCACHED_DOWNLOAD_URL`           | Custom download URL for memcached binary or source archive                                                                                                                | `none`                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
