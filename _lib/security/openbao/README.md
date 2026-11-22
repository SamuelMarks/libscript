# Openbao

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openbao` component (part
of `_server`) within the LibScript ecolibscript_native. OpenBao is an open-source tool for managing
secrets and protecting sensitive data.

## Usage

This directory contains the installation and configuration scripts for `openbao`. This component
works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the
global version manager `libscript`.

Furthermore, OpenBao can be used by libscript to build bigger stacks (like WordPress, Open edX,
Nextcloud, etc.) by providing secure secrets management to these applications.

### Usage with LibScript

You can easily manage the lifecycle of OpenBao using the global `libscript` command or the local
CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install openbao

./cli.sh install openbao

./libscript.sh start openbao
./cli.sh start openbao

./libscript.sh stop openbao
./cli.sh stop openbao

./libscript.sh package-as docker openbao
./cli.sh package-as docker openbao

./libscript.sh uninstall openbao
./cli.sh uninstall openbao
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install openbao

:: Local CLI
cli.cmd install openbao

:: Start and Stop
libscript.cmd start openbao
cli.cmd start openbao

libscript.cmd stop openbao
cli.cmd stop openbao

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi openbao
cli.cmd package-as msi openbao

:: Uninstall
libscript.cmd uninstall openbao
cli.cmd uninstall openbao
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                                                                             | Default             | Aliases/Examples |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ---------------- |
| `OPENBAO_VERSION`                 | Specific version of openbao to install. Can be a numeric version or an alias.                                                                                           | `latest`            | latest, stable   |
| `OPENBAO_INSTALL_METHOD`          | How to install OPENBAO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native`  |                  |
| `LIBSCRIPT_LISTEN_PORT`           | Global port to listen on                                                                                                                                                | `none`              |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`        | Global address to listen on                                                                                                                                             | `none`              |                  |
| `LIBSCRIPT_LISTEN_SOCKET`         | Global unix socket to listen on                                                                                                                                         | `none`              |                  |
| `OPENBAO_LISTEN_PORT`             | Port for OPENBAO to listen on                                                                                                                                           | `none`              |                  |
| `OPENBAO_LISTEN_ADDRESS`          | Address for OPENBAO to listen on                                                                                                                                        | `none`              |                  |
| `OPENBAO_LISTEN_SOCKET`           | Unix socket for OPENBAO to listen on                                                                                                                                    | `none`              |                  |
| `OPENBAO_SERVICE_RUN_AS_USER`     | Windows local user account to run the service under (leave empty for Network Service).                                                                                  | `none`              |                  |
| `OPENBAO_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                                            | `none`              |                  |
| `OPENBAO_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations).                                                                                                | `libscript_openbao` |                  |
| `OPENBAO_DOWNLOAD_URL`            | Override URL for downloading openbao binary or archive artifacts.                                                                                                       | `none`              |                  |
| `OPENBAO_RELEASES_URL`            | Override URL for querying openbao available remote releases.                                                                                                            | `none`              |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
