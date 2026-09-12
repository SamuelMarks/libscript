# Celery

## Purpose & Current State

This document describes the `celery` task queue and worker component (part of `_storage`) within the
LibScript ecosystem.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript`
command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for Celery. You can
manage Celery directly in an isolated, local context, or orchestrate it globally.

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger,
complex stacks (like WordPress, Open edX, Nextcloud, custom data pipelines, etc.) by defining it as
a dependency in your deployment configurations.

## Usage

You can easily install, uninstall, start, stop, and package Celery using the LibScript CLI:

### Installation

**Unix (Linux/macOS):**

```sh
./cli.sh install celery

libscript install celery
```

**Windows:**

```cmd
cli.cmd install celery
```

### Start & Stop

```sh
./cli.sh start celery
./cli.sh stop celery
```

### Uninstallation

```sh
./cli.sh uninstall celery
```

### Packaging

LibScript can package this component into various deployment formats:

```sh
libscript package-as docker celery
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                                               | Default  | Aliases/Examples |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `JUPYTERHUB_SERVICE_USER`         | User (try-create); use for the daemon                                                                                                     | `none`   |                  |
| `PYTHON_VENV`                     | Python virtualenv to install & then start the celery daemon from                                                                          | `none`   |                  |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`       | Global package manager override for Windows targets (e.g. winget, choco).                                                                 | `winget` |                  |
| `CELERY_SERVICE_USER`             | Variable CELERY_SERVICE_USER.                                                                                                             | `none`   |                  |
| `PREFIX`                          | Installation prefix.                                                                                                                      | `none`   |                  |
| `LIBSCRIPT_LOG_DRIVER`            | Logging driver to use (e.g., fluentd).                                                                                                    | `none`   |                  |
| `LIBSCRIPT_LOG_HOST`              | Host for remote logging.                                                                                                                  | `none`   |                  |
| `GROUP`                           | Variable GROUP.                                                                                                                           | `none`   |                  |
| `LIBSCRIPT_LOG_PORT`              | Port for remote logging.                                                                                                                  | `none`   |                  |
| `PYTHON_VERSION`                  | Variable PYTHON_VERSION.                                                                                                                  | `none`   |                  |
| `FORMAT`                          | Output format (e.g., json, text).                                                                                                         | `none`   |                  |
| `LOGS_DIR`                        | Directory where logs should be stored.                                                                                                    | `none`   |                  |
| `SERVE_FROM`                      | Base directory or context path from which the service should be served.                                                                   | `none`   |                  |
| `LIBSCRIPT_VERSION`               | Specifies the version of the package to use.                                                                                              | `none`   |                  |
| `VAULT_TOKEN`                     | Token for HashiCorp Vault authentication.                                                                                                 | `none`   |                  |
| `LIBSCRIPT_SERVICE_NAME`          | Overrides the default service name.                                                                                                       | `none`   |                  |

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

- `_lib/languages/python`: Python runtime and Celery worker engine
- `_lib/message-brokers/rabbitmq` (or `_lib/caches/redis`): Distributed message broker and results
  backend
