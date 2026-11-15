# Etcd

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `etcd` component (part of
`_storage`) within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**etcd**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of etcd, and it can be invoked seamlessly
from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this etcd component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Open edX, Nextcloud, and more).

You can install, start, stop, package, and uninstall etcd using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

libscript install etcd

libscript start etcd
libscript stop etcd

libscript package-as docker etcd

libscript uninstall etcd
```

**Windows:**

```cmd
:: Install
libscript.cmd install etcd

:: Start and Stop
libscript.cmd start etcd
libscript.cmd stop etcd

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi etcd

:: Uninstall
libscript.cmd uninstall etcd
```

_Alternatively, you can execute these locally from within this directory using
`./cli.sh install etcd` or `cli.cmd install etcd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                                          | Default            | Aliases/Examples |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ETCD_VERSION`                 | Version of PostgreSQL demanded                                                                                                                                       | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`        | Global port to listen on                                                                                                                                             | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`     | Global address to listen on                                                                                                                                          | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`      | Global unix socket to listen on                                                                                                                                      | `none`             |                  |
| `ETCD_LISTEN_PORT`             | Port for ETCD to listen on                                                                                                                                           | `none`             |                  |
| `ETCD_LISTEN_ADDRESS`          | Address for ETCD to listen on                                                                                                                                        | `none`             |                  |
| `ETCD_LISTEN_SOCKET`           | Unix socket for ETCD to listen on                                                                                                                                    | `none`             |                  |
| `ETCD_DATA_DIR`                | Directory for Etcd data                                                                                                                                              | `none`             |                  |
| `ETCD_SERVICE_RUN_AS_USER`     | Windows local user account to run the service (leave empty for Network Service)                                                                                      | `none`             |                  |
| `ETCD_SERVICE_RUN_AS_PASSWORD` | Password for the local user account (if applicable)                                                                                                                  | `none`             |                  |
| `ETCD_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations)                                                                                              | `libscript_etcd`   |                  |
| `ETCD_SERVICE_USER`            | User for etcd service.                                                                                                                                               | `none`             |                  |
| `ETCD_URL`                     | URL for etcd.                                                                                                                                                        | `none`             |                  |
| `ETCD_SERVICE_GROUP`           | Group for etcd service.                                                                                                                                              | `none`             |                  |
| `ETCD_INSTALL_METHOD`          | How to install ETCD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `ETCD_DOWNLOAD_URL`            | Override URL for downloading etcd binary or archive artifacts.                                                                                                       | `none`             |                  |
| `ETCD_PASSWORD_FILE`           | Configuration variable ETCD_PASSWORD_FILE for etcd.                                                                                                                  | `none`             |                  |
| `ETCD_RELEASES_URL`            | Override URL for querying etcd available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
