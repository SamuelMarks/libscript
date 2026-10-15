# Swift

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `swift` component (part of
`_toolchain`) within the LibScript ecosystem. This component manages the installation of the Swift
programming language toolchain, enabling you to build applications for macOS, iOS, Linux, and
Windows.

Crucially, this module allows `swift` to function both as a **local version manager** (similar to
tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global
version manager, `libscript`. Furthermore, `libscript` can utilize this `swift` toolchain as a
foundational building block to provision and orchestrate much larger, complex software stacks (such
as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript

This directory contains the installation and configuration scripts for `swift`. It is designed to be
executed via the global `libscript.sh` router or directly via `cli.sh`.

You can install, start, stop, package, and uninstall swift using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install swift

./cli.sh install swift

./libscript.sh start swift
./cli.sh start swift

./libscript.sh stop swift
./cli.sh stop swift

./libscript.sh package-as docker swift
./cli.sh package-as docker swift

./libscript.sh uninstall swift
./cli.sh uninstall swift
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install swift

:: Local CLI
cli.cmd install swift

:: Start and Stop
libscript.cmd start swift
cli.cmd start swift

libscript.cmd stop swift
cli.cmd stop swift

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi swift
cli.cmd package-as msi swift

:: Uninstall
libscript.cmd uninstall swift
cli.cmd uninstall swift
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`         |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                     |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                  |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `SWIFT_INSTALL_METHOD`             | How to install SWIFT. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools.                                                                                                                                                           | `libscript_native`         |                  |
| `SWIFT_VERSION`                    | Version of Swift Toolchain to install                                                                                                                                                                                                                                                                                           | `5.10`                     |                  |

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
