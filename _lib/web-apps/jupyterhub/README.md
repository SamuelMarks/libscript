# Jupyterhub

## Usage

This document describes the `JupyterHub` component located in the `third_party` folder within the
LibScript ecosystem. It provides the installation and configuration scripts required to provision
JupyterHub.

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. Furthermore, JupyterHub can be used by libscript to build
bigger stacks (like WordPress, Open edX, nextcloud, etc.) when combined with databases and web
servers.

You can manage JupyterHub using the global `libscript` CLI or the local scripts.

- **Install:** `libscript install jupyterhub`
- **Uninstall:** `libscript uninstall jupyterhub`
- **Start:** `libscript start jupyterhub`
- **Stop:** `libscript stop jupyterhub`
- **Package:** `libscript package-as docker jupyterhub` (or `msi`, `docker_compose`, etc.)

**Unix (Linux/macOS) Local Invocation:**

```sh
./cli.sh install jupyterhub
```

**Windows Local Invocation:**

```cmd
cli.cmd install jupyterhub
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                    | Default                    | Aliases/Examples |
| ---------------------------------- | ---------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed (system vs libscript_native).             | `libscript_native`         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco).                                   | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                           | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                           | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                        | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                            | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                          | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                              | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                       | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.   | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted. | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                            | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                         | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                         | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                      | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                           | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                       | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                   | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                       | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                  | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                            | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                              | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                 | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                   | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                           | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                              | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                       | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                       | `none`                     |                  |
| `JUPYTERHUB_SERVICE_USER`          | Username to use for the install + daemon serve (creates user if nonexistent)                   | `none`                     |                  |
| `JUPYTERHUB_IP`                    | IP address to server from                                                                      | `none`                     |                  |
| `JUPYTERHUB_PORT`                  | IP port to server from                                                                         | `none`                     |                  |
| `JUPYTERHUB_NOTEBOOK_DIR`          | Notebook directory (creates if nonexistent)                                                    | `none`                     |                  |
| `JUPYTERHUB_VENV`                  | Python virtualenv to use (creates if nonexistent)                                              | `none`                     |                  |
| `JUPYTERHUB_PASSWORD`              | Preferably (hashed+salted argon2) password to use                                              | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                           | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                         | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                       | `none`                     |                  |
| `JUPYTERHUB_SERVICE_GROUP`         | Variable JUPYTERHUB_SERVICE_GROUP.                                                             | `none`                     |                  |
| `GROUP`                            | Variable GROUP.                                                                                | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                       | `none`                     |                  |
| `PYTHON_VERSION`                   | Variable PYTHON_VERSION.                                                                       | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                              | `none`                     |                  |
| `JUPYTERHUB_USERNAME`              | Variable JUPYTERHUB_USERNAME.                                                                  | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                         | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path from which the service should be served.                        | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                   | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                      | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                            | `none`                     |                  |

<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Orchestrated Components

This stack orchestrates the following LibScript components:

- `_lib/languages/python`: Python runtime and Jupyter kernel environment
- `_lib/languages/nodejs`: Node.js runtime for configurable HTTP proxy (`configurable-http-proxy`)
- `_lib/web-servers/nginx` (or `caddy`, `httpd`): Reverse proxy for notebook routing
