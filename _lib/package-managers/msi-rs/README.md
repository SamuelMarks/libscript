# msi-rs

Bootstrap module for the `msi-rs` package manager and Windows Installer (`.msi`) manipulation and
execution toolchain.

## Overview

`msi-rs` is a pure-Rust, cross-platform implementation of the Windows Installer technology stack. It
serves as a modern drop-in replacement for the WiX Toolset, `msitools`, and Microsoft's
`msiexec.exe` runtime across Windows, Linux, macOS, FreeBSD, and SunOS/Solaris.

The installer automates dependency resolution for the required C compiler toolchain and Rust/Cargo
environment, installs version-isolated binaries under `~/.libscript/msi-rs/<version>/bin`, and
manages active symlink aliases.

### Provided Binaries & Utilities

Installing `msi-rs` provides:

- **Installer CLI & Runtime:** `msi-cli`, `msi-rs`, `msi`
- **WiX Toolset Replacement Suite:** `candle`, `light`, `wix`, `dark`, `heat`, `torch`, `pyro`,
  `lit`, `smoke`
- **MSI Inspection & Build Tools:** `msiinfo`, `msibuild`, `msidump`, `msidiff`, `msiextract`
- **Graphical Installer Interface:** `msi-gui` (when graphics dependencies are present)

## Usage

Install and configure `msi-rs`:

```sh
# Install default/latest version
./libscript.sh install msi-rs latest

# Set default active version
./libscript.sh use msi-rs 0.0.1

# Run test suite
./libscript.sh test msi-rs

# Load into shell environment
. $(./libscript.sh env msi-rs latest)
```

On Windows Command Prompt:

```cmd
:: Install msi-rs
libscript.cmd install msi-rs latest

:: Run component test
libscript.cmd test msi-rs
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                            | Default                                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                     | `libscript_native`                         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                           | `winget`                                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                   | `1`                                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                   | `text`                                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                | `none`                                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                    | `none`                                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                  | `none`                                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                      | `none`                                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                               | `none`                                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                           | `0`                                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                         | `0`                                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                    | `none`                                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                 | `none`                                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                 | `none`                                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                              | `none`                                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                   | `none`                                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                        | `none`                                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                               | `none`                                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                           | `none`                                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                               | `none`                                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                          | `us-central2-b`                            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                    | `v4-8`                                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                      | `tpu-ubuntu2204-base`                      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                         | `none`                                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                           | `none`                                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                   | `1`                                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                      | `your-org/your-model-name`                 |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                               | `none`                                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                               | `none`                                     |                  |
| `MSI_RS_INSTALL_METHOD`            | How to install msi-rs. 'libscript_native' builds and isolates version dirs, 'cargo' installs via cargo, or 'system' defers to system package managers. | `libscript_native`                         |                  |
| `MSI_RS_VERSION`                   | Specific version or release tag of msi-rs to install.                                                                                                  | `c075557d4fe8f8fb32183a5160a68779fbc8b708` |                  |
| `MSI_RS_REPO_URL`                  | Upstream source Git repository URL for msi-rs.                                                                                                         | `https://github.com/SamuelMarks/msi-rs`    |                  |
| `MSI_RS_DOWNLOAD_URL`              | Direct download URL for prebuilt binary archive if available.                                                                                          | `none`                                     |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Testing

Testing is strictly restricted to isolated Vagrant virtual machines across
`{macOS, Windows, FreeBSD, SunOS, Linux}`.

```sh
# Run multi-platform Vagrant verification
./tests/test_msi_rs_vagrant.sh --all

# Or on Windows Command Prompt:
.\tests\test_msi_rs_vagrant.cmd --all
```
