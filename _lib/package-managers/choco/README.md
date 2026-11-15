# Choco

## Usage

This document describes **Chocolatey (choco)**, a machine-level, command-line package manager and
installer for Windows software.

Chocolatey works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked
from the global version manager `libscript`. Furthermore, it can be used by libscript as a
foundational tool to build and provision bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall choco using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install choco

./cli.sh install choco

./libscript.sh start choco
./cli.sh start choco

./libscript.sh stop choco
./cli.sh stop choco

./libscript.sh package-as docker choco
./cli.sh package-as docker choco

./libscript.sh uninstall choco
./cli.sh uninstall choco
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install choco

:: Local CLI
cli.cmd install choco

:: Start and Stop
libscript.cmd start choco
cli.cmd start choco

libscript.cmd stop choco
cli.cmd stop choco

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi choco
cli.cmd package-as msi choco

:: Uninstall
libscript.cmd uninstall choco
cli.cmd uninstall choco
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CHOCO_INSTALL_METHOD` | How to install CHOCO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `CHOCO_VERSION`        | Specific version of choco to install.                                                                                                                                 | `latest`           |                  |
| `CHOCO_DOWNLOAD_URL`   | Override URL for downloading choco binary or archive artifacts.                                                                                                       | `none`             |                  |
| `CHOCO_RELEASES_URL`   | Override URL for querying choco available remote releases.                                                                                                            | `none`             |                  |
| `CHOCO_SOURCE`         | Configuration variable CHOCO_SOURCE for choco.                                                                                                                        | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
