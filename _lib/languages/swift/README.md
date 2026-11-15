# Swift

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `swift` component (part of
`_toolchain`) within the LibScript ecosystem. This component manages the installation of the Swift
programming language toolchain, enabling you to build applications for macOS, iOS, Linux, and
Windows.

Crucially, this module allows `swift` to function both as a **local version manager** (similar to
tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global
version manager, `libscript`. Furthermore, `libscript` can utilize this `swift` toolchain as a
foundational building block to provision and orchestrate much larger, complex software stacks (such
as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript

This directory contains the installation and configuration scripts for `swift`. It is designed to be
executed via the global `libscript.sh` router or directly via `cli.sh`.

You can install, start, stop, package, and uninstall swift using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install swift

./cli.sh install swift

./libscript.sh start swift
./cli.sh start swift

./libscript.sh stop swift
./cli.sh stop swift

./libscript.sh package-as docker swift
./cli.sh package-as docker swift

./libscript.sh uninstall swift
./cli.sh uninstall swift
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install swift

:: Local CLI
cli.cmd install swift

:: Start and Stop
libscript.cmd start swift
cli.cmd start swift

libscript.cmd stop swift
cli.cmd stop swift

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi swift
cli.cmd package-as msi swift

:: Uninstall
libscript.cmd uninstall swift
cli.cmd uninstall swift
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SWIFT_INSTALL_METHOD` | How to install SWIFT. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `SWIFT_VERSION`        | Version of Swift Toolchain to install                                                                                                                                 | `5.10`             |                  |
| `SWIFT_DOWNLOAD_URL`   | Override URL for downloading swift binary or archive artifacts.                                                                                                       | `none`             |                  |
| `SWIFT_RELEASES_URL`   | Override URL for querying swift available remote releases.                                                                                                            | `none`             |                  |

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
