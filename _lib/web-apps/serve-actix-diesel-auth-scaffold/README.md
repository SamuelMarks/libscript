# Serve Actix Diesel Auth Scaffold

## Purpose & Current State

This document describes the `serve-actix-diesel-auth-scaffold` component within the LibScript
ecosystem. This component acts as a scaffolding tool and template for Rust-based web applications
using Actix, Diesel, and authentication middleware.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript`
command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for this component.
You can manage `serve-actix-diesel-auth-scaffold` directly in an isolated, local context, or
orchestrate it globally.

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger,
complex stacks (like WordPress, Open edX, Nextcloud, custom SaaS platforms, etc.) by defining it as
a dependency in your deployment configurations.

## Usage

You can easily install, uninstall, start, stop, and package this component using the LibScript CLI:

### Installation

**Unix (Linux/macOS):**

```sh
./cli.sh install serve-actix-diesel-auth-scaffold

libscript install serve-actix-diesel-auth-scaffold
```

**Windows:**

```cmd
cli.cmd install serve-actix-diesel-auth-scaffold

libscript.cmd install serve-actix-diesel-auth-scaffold
```

### Start & Stop

```sh
./cli.sh start serve-actix-diesel-auth-scaffold
./cli.sh stop serve-actix-diesel-auth-scaffold
```

### Uninstallation

```sh
./cli.sh uninstall serve-actix-diesel-auth-scaffold
```

### Packaging

LibScript can package this component into various deployment formats:

```sh
libscript package-as docker serve-actix-diesel-auth-scaffold
libscript package-as msi serve-actix-diesel-auth-scaffold
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct installation script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                                     | Description                                                                                    | Default                    | Aliases/Examples |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD`           | Global override for how software should be installed (system vs libscript_native).             | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`                  | Global package manager override for Windows (winget, choco).                                   | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`                        | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                           | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`                       | Output format for logs (text, json).                                                           | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`                         | File to write logs to (in addition to standard output).                                        | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`                     | Overrides the default service name.                                                            | `none`                     |                  |
| `DOWNLOAD_DIR`                               | Directory where downloads are stored.                                                          | `none`                     |                  |
| `FORMAT`                                     | Output format (e.g., json, text).                                                              | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`                        | Directory where cached files are stored.                                                       | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                          | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.   | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`                    | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted. | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`                     | Staging directory for temporary download artifacts.                                            | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`                       | Logging driver to use (e.g., fluentd).                                                         | `none`                     |                  |
| `LOGS_DIR`                                   | Directory where logs should be stored.                                                         | `none`                     |                  |
| `VAULT_TOKEN`                                | Token for HashiCorp Vault authentication.                                                      | `none`                     |                  |
| `PREFIX`                                     | Installation prefix.                                                                           | `none`                     |                  |
| `SERVE_FROM`                                 | Base directory or context path for the service.                                                | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`                         | Host for remote logging.                                                                       | `none`                     |                  |
| `LIBSCRIPT_VERSION`                          | Specifies the version of the package to use.                                                   | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`                         | Port for remote logging.                                                                       | `none`                     |                  |
| `TPU_ZONE`                                   | GCP Zone for TPU provisioning                                                                  | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`                       | Type of TPU accelerator (e.g. v4-8)                                                            | `v4-8`                     |                  |
| `TPU_VERSION`                                | TPU VM OS version                                                                              | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                             | GCP Project ID                                                                                 | `none`                     |                  |
| `XPK_CLUSTER_NAME`                           | Name for the XPK GKE cluster                                                                   | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`                   | Tensor parallel size for TPU serving                                                           | `1`                        |                  |
| `MODEL_NAME`                                 | HuggingFace model string to serve                                                              | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                              | Name of the XPK workload                                                                       | `none`                     |                  |
| `JETSTREAM_IMAGE`                            | Docker image for JetStream TPU inference                                                       | `none`                     |                  |
| `SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR` | Variable SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR.                                           | `none`                     |                  |
| `BUILD_DIR`                                  | Variable BUILD_DIR.                                                                            | `none`                     |                  |
| `REPOS_DIR`                                  | Variable REPOS_DIR.                                                                            | `none`                     |                  |
| `SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST`      | Variable SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST.                                                | `none`                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/rust`: Rust toolchain, `cargo`, and build utilities
- `_lib/databases/postgres` (or `sqlite`): Relational persistence layer for user auth and data
