# BusyBox

## Purpose & Current State

This directory contains the installation and configuration scripts for **Busybox** within the
LibScript ecolibscript_native. Busybox is a software suite that provides several Unix utilities in a
single executable file.

This module works both as a local version manager for Busybox (similar to `rvm`, `nvm`, `pyenv`, or
`uv`) and can be seamlessly invoked from the global version manager `libscript`. It allows LibScript
to use Busybox as a core dependency to build bigger, more complex software stacks (such as
WordPress, Open edX, Nextcloud, etc.).

## Usage

_Note: libscript manages versions natively for this component._

You can install, start, stop, package, and uninstall busybox using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install busybox

./cli.sh install busybox

./libscript.sh start busybox
./cli.sh start busybox

./libscript.sh stop busybox
./cli.sh stop busybox

./libscript.sh package-as docker busybox
./cli.sh package-as docker busybox

./libscript.sh uninstall busybox
./cli.sh uninstall busybox
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install busybox

:: Local CLI
cli.cmd install busybox

:: Start and Stop
libscript.cmd start busybox
cli.cmd start busybox

libscript.cmd stop busybox
cli.cmd stop busybox

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi busybox
cli.cmd package-as msi busybox

:: Uninstall
libscript.cmd uninstall busybox
cli.cmd uninstall busybox
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                                             | Default  | Aliases/Examples |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `BUSYBOX_INSTALL_METHOD` | How to install BUSYBOX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `BUSYBOX_VERSION`        | Specific version of busybox to install.                                                                                                                                 | `latest` |                  |
| `BUSYBOX_DOWNLOAD_URL`   | Override URL for downloading busybox binary or archive artifacts.                                                                                                       | `none`   |                  |
| `BUSYBOX_RELEASES_URL`   | Override URL for querying busybox available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
