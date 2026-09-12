# PowerShell

## Usage

_Note: libscript manages versions natively for this component._

This document describes the **PowerShell** bootstrap component within the LibScript
ecolibscript_native. It is responsible for provisioning and managing the PowerShell environment on
target libscript_natives.

This component operates efficiently as a **local version manager** (similar to rvm, nvm, pyenv, uv)
to manage your PowerShell installation. Furthermore, it can be directly invoked from the **global
version manager**, `libscript`. This integration ensures that PowerShell can be seamlessly used by
`libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall powershell using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install powershell

./cli.sh install powershell

./libscript.sh start powershell
./cli.sh start powershell

./libscript.sh stop powershell
./cli.sh stop powershell

./libscript.sh package-as docker powershell
./cli.sh package-as docker powershell

./libscript.sh uninstall powershell
./cli.sh uninstall powershell
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install powershell

:: Local CLI
cli.cmd install powershell

:: Start and Stop
libscript.cmd start powershell
cli.cmd start powershell

libscript.cmd stop powershell
cli.cmd stop powershell

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi powershell
cli.cmd package-as msi powershell

:: Uninstall
libscript.cmd uninstall powershell
cli.cmd uninstall powershell
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                | Default                    | Aliases/Examples |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                                         | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                                               | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                       | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                       | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                        | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                      | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                   | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                     | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                     | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                  | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                       | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                            | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                   | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                   | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                              | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                        | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                          | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                             | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                               | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                       | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                          | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                   | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                   | `none`                     |                  |
| `POWERSHELL_INSTALL_METHOD`        | How to install POWERSHELL. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system`                   |                  |
| `POWERSHELL_VERSION`               | Specific version of PowerShell to install.                                                                                                                                 | `latest`                   |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
