# Wait4X

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `wait4x` component (part
of `_toolchain`) within the LibScript ecolibscript_native. `wait4x` is a command-line tool that
allows you to wait for various ports and services (like databases, HTTP servers, or generic TCP
sockets) to become available, making it invaluable for reliable CI/CD and orchestration flows.

Crucially, this module allows `wait4x` to function both as a **local version manager** (similar to
tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global
version manager, `libscript`. Furthermore, `libscript` can utilize this `wait4x` toolchain as a
foundational building block to provision and orchestrate much larger, complex software stacks (such
as WordPress, Open edX, Nextcloud, and more) where service startup synchronization is required.

## Usage

_Note: libscript manages versions natively for this component._ with LibScript

This directory contains the installation and configuration scripts for `wait4x`. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

You can install, start, stop, package, and uninstall wait4x using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install wait4x

./cli.sh install wait4x

./libscript.sh start wait4x
./cli.sh start wait4x

./libscript.sh stop wait4x
./cli.sh stop wait4x

./libscript.sh package-as docker wait4x
./cli.sh package-as docker wait4x

./libscript.sh uninstall wait4x
./cli.sh uninstall wait4x
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install wait4x

:: Local CLI
cli.cmd install wait4x

:: Start and Stop
libscript.cmd start wait4x
cli.cmd start wait4x

libscript.cmd stop wait4x
cli.cmd stop wait4x

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi wait4x
cli.cmd package-as msi wait4x

:: Uninstall
libscript.cmd uninstall wait4x
cli.cmd uninstall wait4x
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WAIT4X_INSTALL_METHOD` | How to install WAIT4X. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `WAIT4X_VERSION`        | Specific version of Wait4X to install.                                                                                                                                 | `latest`           |                  |
| `WAIT4X_DOWNLOAD_URL`   | Override URL for downloading wait4x binary or archive artifacts.                                                                                                       | `none`             |                  |
| `WAIT4X_RELEASES_URL`   | Override URL for querying wait4x available remote releases.                                                                                                            | `none`             |                  |

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
