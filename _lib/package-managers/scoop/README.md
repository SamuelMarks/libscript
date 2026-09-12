# Scoop

## Usage

This document describes the **Scoop** bootstrap component within the LibScript ecolibscript_native.
Scoop is a command-line installer for Windows that eliminates permission popup windows and hides GUI
wizard dialogs.

The Scoop component functions as a **local version manager** (similar to rvm, nvm, pyenv, uv) for
managing Windows tools, while also being capable of being invoked directly from the **global version
manager**, `libscript`. Through this capability, Scoop is heavily used by `libscript` on Windows
platforms to resolve dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud,
etc.).

You can install, start, stop, package, and uninstall scoop using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install scoop

./cli.sh install scoop

./libscript.sh start scoop
./cli.sh start scoop

./libscript.sh stop scoop
./cli.sh stop scoop

./libscript.sh package-as docker scoop
./cli.sh package-as docker scoop

./libscript.sh uninstall scoop
./cli.sh uninstall scoop
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install scoop

:: Local CLI
cli.cmd install scoop

:: Start and Stop
libscript.cmd start scoop
cli.cmd start scoop

libscript.cmd stop scoop
cli.cmd stop scoop

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi scoop
cli.cmd package-as msi scoop

:: Uninstall
libscript.cmd uninstall scoop
cli.cmd uninstall scoop
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                           | Default                    | Aliases/Examples |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                                    | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                                          | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                  | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                  | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                   | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                 | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                     | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                             | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                  | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                       | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                          | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                              | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                         | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                   | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                     | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                        | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                          | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                  | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                     | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                              | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                              | `none`                     |                  |
| `SCOOP_INSTALL_METHOD`             | How to install SCOOP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`         |                  |
| `SCOOP_VERSION`                    | Specific version of scoop to install.                                                                                                                                 | `latest`                   |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
