# C

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `c` component (part of
`_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is C?**: C is a powerful, general-purpose procedural computer programming language supporting
structured programming, lexical variable scope, and recursion, widely used for system programming
and embedded systems.

## Usage

This directory contains the installation and configuration scripts for `c`.

### Local and Global Version Management

The `c` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`,
`pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`.
This dual capability allows developers to manage specific versions per project locally or enforce
system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build,
deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like
WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can
orchestrate `c` toolchains alongside databases, web servers, and other services to form a cohesive,
reproducible stack.

You can install, start, stop, package, and uninstall c using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install c

./cli.sh install c

./libscript.sh start c
./cli.sh start c

./libscript.sh stop c
./cli.sh stop c

./libscript.sh package_as docker c
./cli.sh package_as docker c

./libscript.sh uninstall c
./cli.sh uninstall c
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install c

:: Local CLI
cli.cmd install c

:: Start and Stop
libscript.cmd start c
cli.cmd start c

libscript.cmd stop c
cli.cmd stop c

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi c
cli.cmd package_as msi c

:: Uninstall
libscript.cmd uninstall c
cli.cmd uninstall c
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
| Variable | Description | Default | Aliases/Examples |
|---|---|---|---|
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript-native). | `libscript-native` |  |
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
| `C_INSTALL_METHOD` | How to install C. 'system' uses the native OS package manager, 'source' compiles/downloads binaries. | `system` |  |
| `C_VERSION` | Version of C Toolchain to install | `latest` |  |
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
