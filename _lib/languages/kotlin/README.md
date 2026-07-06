# Kotlin

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `kotlin` component (part
of `_toolchain`) within the LibScript ecosystem. Kotlin is a modern, cross-platform, statically
typed programming language designed to interoperate fully with Java, while providing more concise
and safer syntax. LibScript is a modular, zero-dependency shell-script framework designed for
cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

This directory contains the installation and configuration scripts for `kotlin`. It works both as a
local version manager (similar to rvm, nvm, pyenv, uv) for Kotlin and can be invoked from the global
version manager `libscript`. Furthermore, it can be used by libscript as a building block to
assemble bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall kotlin using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install kotlin

./cli.sh install kotlin

./libscript.sh start kotlin
./cli.sh start kotlin

./libscript.sh stop kotlin
./cli.sh stop kotlin

./libscript.sh package-as docker kotlin
./cli.sh package-as docker kotlin

./libscript.sh uninstall kotlin
./cli.sh uninstall kotlin
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install kotlin

:: Local CLI
cli.cmd install kotlin

:: Start and Stop
libscript.cmd start kotlin
cli.cmd start kotlin

libscript.cmd stop kotlin
cli.cmd stop kotlin

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi kotlin
cli.cmd package-as msi kotlin

:: Uninstall
libscript.cmd uninstall kotlin
cli.cmd uninstall kotlin
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
| `KOTLIN_INSTALL_METHOD` | How to install KOTLIN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
| `KOTLIN_VERSION` | Version of Kotlin Toolchain to install | `1.9.20` |  |
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

Libscript manages kotlin versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/kotlin/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
