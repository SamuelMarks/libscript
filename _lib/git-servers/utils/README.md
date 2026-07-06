# Git Servers

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_git` component (part of
`_lib`) within the LibScript ecolibscript_native. This component is responsible for installing,
managing, and configuring **Git**, the widely used distributed version control libscript_native. It
provides the necessary scripts to provision Git across supported operating libscript_natives
efficiently.

## Usage

This directory contains the scripts for managing Git. It is designed to work both as a local version
manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for isolated project-level Git installations,
and can also be seamlessly invoked from the global version manager `libscript`.

Additionally, this component can be utilized by LibScript as a foundational dependency to build and
provision bigger stacks, such as WordPress, Open edX, Nextcloud, and other complex software
environments.

You can install, start, stop, package, and uninstall git-servers using the global `libscript`
command or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install git-servers

./cli.sh install git-servers

./libscript.sh start git-servers
./cli.sh start git-servers

./libscript.sh stop git-servers
./cli.sh stop git-servers

./libscript.sh package-as docker git-servers
./cli.sh package-as docker git-servers

./libscript.sh uninstall git-servers
./cli.sh uninstall git-servers
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install git-servers

:: Local CLI
cli.cmd install git-servers

:: Start and Stop
libscript.cmd start git-servers
cli.cmd start git-servers

libscript.cmd stop git-servers
cli.cmd stop git-servers

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi git-servers
cli.cmd package-as msi git-servers

:: Uninstall
libscript.cmd uninstall git-servers
cli.cmd uninstall git-servers
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
| `1` | repository | `none` |  |
| `2` | target directory | `none` |  |
| `3` | branch | `none` |  |
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

Libscript manages utils versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/utils/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
