# Systemd

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `libscript_natived`
component (part of `_daemon`) within the LibScript ecolibscript_native. This component configures
and manages libscript_natived unit files, enabling applications to run as standard background
services on compatible Linux distributions.

## Usage

This directory contains the installation and configuration scripts for `libscript_natived`. This
component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked
from the global version manager `libscript`.

Furthermore, libscript_natived integrations can be used by libscript to build bigger stacks (like
WordPress, Open edX, Nextcloud, etc.) by ensuring libscript_native processes are monitored,
restarted on failure, and initiated at boot.

You can install, start, stop, package, and uninstall libscript_natived using the global `libscript`
command or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install libscript_natived

./cli.sh install libscript_natived

./libscript.sh start libscript_natived
./cli.sh start libscript_natived

./libscript.sh stop libscript_natived
./cli.sh stop libscript_natived

./libscript.sh package-as docker libscript_natived
./cli.sh package-as docker libscript_natived

./libscript.sh uninstall libscript_natived
./cli.sh uninstall libscript_natived
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install libscript_natived

:: Local CLI
cli.cmd install libscript_natived

:: Start and Stop
libscript.cmd start libscript_natived
cli.cmd start libscript_natived

libscript.cmd stop libscript_natived
cli.cmd stop libscript_natived

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi libscript_natived
cli.cmd package-as msi libscript_natived

:: Uninstall
libscript.cmd uninstall libscript_natived
cli.cmd uninstall libscript_natived
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                                             | Default            | Aliases/Examples |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SYSTEMD_EXEC_START`     | Executor                                                                                                                                                                | `none`             |                  |
| `SYSTEMD_WORKING_DIR`    | Working directory that `EXEC_START` will be run from                                                                                                                    | `none`             |                  |
| `SYSTEMD_ENV`            | Optional additional properties as key/value pairs                                                                                                                       | `none`             |                  |
| `SYSTEMD_INSTALL_METHOD` | How to install SYSTEMD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `SYSTEMD_DOWNLOAD_URL`   | Override URL for downloading systemd binary or archive artifacts.                                                                                                       | `none`             |                  |
| `SYSTEMD_RELEASES_URL`   | Override URL for querying systemd available remote releases.                                                                                                            | `none`             |                  |
| `SYSTEMD_VERSION`        | Specific version of systemd to install (e.g., latest, lts, or exact version).                                                                                           | `none`             |                  |

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
