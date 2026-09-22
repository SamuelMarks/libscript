# Brew

Homebrew is a free and open-source software package management libscript_native that simplifies the
installation of software on macOS and Linux. It builds packages from source and provides
pre-compiled binaries, making it easy to manage dependencies and development tools.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

Homebrew can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud,
etc.).

## Usage

You can manage Homebrew using libscript with the following commands:

- **Install**: `libscript install brew`
- **Uninstall**: `libscript uninstall brew`
- **Start**: `libscript start brew`
- **Stop**: `libscript stop brew`
- **Package**: `libscript package brew`

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                          | Default                    | Aliases/Examples |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).                                                                                   | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                                                                                         | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                 | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                 | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                  | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                         | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                       | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                               | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                               | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                            | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                 | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                      | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                             | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                        | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                  | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                    | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                       | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                         | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                 | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                    | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                             | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                             | `none`                     |                  |
| `BREW_INSTALL_METHOD`              | How to install BREW. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`         |                  |
| `BREW_VERSION`                     | Specific version of brew to install.                                                                                                                                 | `latest`                   |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
