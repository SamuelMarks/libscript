# Noop

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_noop` component (part of
`_common`) within the LibScript ecosystem. This module serves as a "no-operation" (noop) placeholder
or dummy component. It is primarily used for testing, structural padding, or safely bypassing
execution paths where a component is required but no actual operation should be performed.

## Usage

This directory contains the configuration scripts for `_noop`. Despite being a dummy component, it
is designed to strictly follow the standard LibScript architecture. It works both as a local version
manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global
version manager `libscript`.

Additionally, the `_noop` module can be utilized by LibScript when dynamically assembling and
building bigger stacks (like WordPress, Open edX, Nextcloud), acting as a safe fallback when
specific dependencies are disabled or intentionally omitted from a stack deployment.

You can install, start, stop, package, and uninstall \_noop using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install _noop

./cli.sh install _noop

./libscript.sh start _noop
./cli.sh start _noop

./libscript.sh stop _noop
./cli.sh stop _noop

./libscript.sh package-as docker _noop
./cli.sh package-as docker _noop

./libscript.sh uninstall _noop
./cli.sh uninstall _noop
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install _noop

:: Local CLI
cli.cmd install _noop

:: Start and Stop
libscript.cmd start _noop
cli.cmd start _noop

libscript.cmd stop _noop
cli.cmd stop _noop

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi _noop
cli.cmd package-as msi _noop

:: Uninstall
libscript.cmd uninstall _noop
cli.cmd uninstall _noop
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

| Variable                           | Description                                                                        | Default                    | Aliases/Examples |
| ---------------------------------- | ---------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native). | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                       | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).               | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                               | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                            | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                              | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                  | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                           | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                             | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                             | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                          | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                               | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                    | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                           | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                       | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                           | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                      | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                  | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                     | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                       | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                               | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                  | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                           | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                           | `none`                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
