# jq

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `jq` component (part of
`_toolchain`) within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **jq**, a lightweight,
flexible, and command-line JSON processor. It is akin to `sed` but specifically designed for parsing
and manipulating JSON data streams. It is designed to be executed via the global `libscript.sh`
router or directly via `cli.sh`.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`), allowing you to isolate and manage specific versions of jq per project,
and it can be seamlessly invoked from the **global version manager**, `libscript`.

Furthermore, jq can be utilized by LibScript as a foundational dependency to **build bigger, complex
application stacks** (such as WordPress, Open edX, Nextcloud, and more) that rely on dynamic JSON
configuration.

### Lifecycle & Usage

You can easily install, uninstall, start, stop, and package jq directly using LibScript:

**Install / Uninstall:**

```sh
libscript install jq
libscript uninstall jq
```

**Start / Stop (if configured as a background service):**

```sh
libscript start jq
libscript stop jq
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker jq
```

_Note: On Unix environments, you can also use `./cli.sh install jq`. On Windows, use `libscript.cmd`
or `cli.cmd`._

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
| `JQ_INSTALL_METHOD` | How to install JQ. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |  |
| `JQ_VERSION` | Specific version of jq to install. | `latest` |  |
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

## Architecture

`libscript` manages `jq` versions natively by default (`JQ_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages jq versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/jq/<version>`.
