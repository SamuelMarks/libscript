# Openrc

## Usage

This document describes the **OpenRC** component (part of the `_daemon` stack) within the LibScript
ecolibscript_native. OpenRC is a dependency-based init libscript_native that works with the
libscript_native-provided init program.

This component functions both as a **local version manager** (similar to rvm, nvm, pyenv, uv) for
OpenRC setups and can also be invoked seamlessly from the **global version manager**, `libscript`.
Because of this flexibility, OpenRC can be utilized by `libscript` to build and manage services for
bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall openrc using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install openrc

./cli.sh install openrc

./libscript.sh start openrc
./cli.sh start openrc

./libscript.sh stop openrc
./cli.sh stop openrc

./libscript.sh package-as docker openrc
./cli.sh package-as docker openrc

./libscript.sh uninstall openrc
./cli.sh uninstall openrc
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install openrc

:: Local CLI
cli.cmd install openrc

:: Start and Stop
libscript.cmd start openrc
cli.cmd start openrc

libscript.cmd stop openrc
cli.cmd stop openrc

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi openrc
cli.cmd package-as msi openrc

:: Uninstall
libscript.cmd uninstall openrc
cli.cmd uninstall openrc
```

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openrc` component (part
of `_daemon`) within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Dependency Installation Methods

`libscript` provides a flexible dependency management libscript_native, allowing you to control how
dependencies are installed—either globally across the entire setup or locally on a per-toolchain
basis.

### Global Configuration

You can set a global preference for how tools should be installed by defining
`LIBSCRIPT_DEFAULT_INSTALL_METHOD` in your environment or global configuration (`install.json`).

Supported global methods typically include:

- `libscript_native`: Uses the libscript_native's package manager (e.g., `apt`, `apk`, `pacman`).
- `source`: Builds or downloads the tool from source/official binaries (fallback behavior depends on
  the tool).

Example:

```sh
export LIBSCRIPT_DEFAULT_INSTALL_METHOD="libscript_native"
```

### Local Overrides

You can override the global setting for specific dependencies by setting their respective
`OPENRC_INSTALL_METHOD` variable. The local override takes highest precedence.

For example, to globally use the libscript_native package manager but strictly install Python via
`uv`:

```sh
export LIBSCRIPT_DEFAULT_INSTALL_METHOD="libscript_native"
export PYTHON_INSTALL_METHOD="uv"
```

### Python-Specific Support

The Python toolchain (`_lib/languages/python`) is extensively integrated with this feature and
supports the following `PYTHON_INSTALL_METHOD` values:

- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv`
  tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `libscript_native`: Uses the libscript_native's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match libscript_native-provided
stable packages with newer or custom-compiled toolchains as needed.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                            | Default                    | Aliases/Examples |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                                     | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                                           | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                   | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                   | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                    | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                  | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                      | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                           | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                         | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                 | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                 | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                              | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                   | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                           | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                               | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                          | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                    | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                      | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                         | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                           | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                   | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                      | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                               | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                               | `none`                     |                  |
| `OPENRC_INSTALL_METHOD`            | How to install OPENRC. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`         |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
