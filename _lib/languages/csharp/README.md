# C

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `csharp` component (part
of `_toolchain`) within the LibScript ecosystem. This component manages the installation of the C#
and .NET platform toolchain, providing the necessary SDKs and runtimes to build and execute .NET
applications.

Crucially, this module allows `csharp` to function both as a **local version manager** (similar to
tools like `rvm`, `nvm`, `pyenv`, or `uv`) and as a component invoked seamlessly by the global
version manager, `libscript`. Furthermore, `libscript` can utilize this `csharp` toolchain as a
foundational building block to provision and orchestrate much larger, complex software stacks (such
as WordPress, Open edX, Nextcloud, and more).

## Usage with LibScript

This directory contains the installation and configuration scripts for `csharp`. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

You can install, start, stop, package, and uninstall csharp using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install csharp

./cli.sh install csharp

./libscript.sh start csharp
./cli.sh start csharp

./libscript.sh stop csharp
./cli.sh stop csharp

./libscript.sh package-as docker csharp
./cli.sh package-as docker csharp

./libscript.sh uninstall csharp
./cli.sh uninstall csharp
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install csharp

:: Local CLI
cli.cmd install csharp

:: Start and Stop
libscript.cmd start csharp
cli.cmd start csharp

libscript.cmd stop csharp
cli.cmd stop csharp

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi csharp
cli.cmd package-as msi csharp

:: Uninstall
libscript.cmd uninstall csharp
cli.cmd uninstall csharp
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CSHARP_INSTALL_METHOD` | How to install CSHARP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `CSHARP_VERSION`        | Version of C# Toolchain to install                                                                                                                                     | `latest`           |                  |
| `CSHARP_DOWNLOAD_URL`   | Override URL for downloading csharp binary or archive artifacts.                                                                                                       | `none`             |                  |
| `CSHARP_RELEASES_URL`   | Override URL for querying csharp available remote releases.                                                                                                            | `none`             |                  |

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
