# Sh

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `sh` component (part of
`_toolchain`) within the LibScript ecosystem. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**What is Shell Scripting (Sh)?**: Shell scripting (Sh) refers to a computer program designed to be
run by the Unix shell, a command-line interpreter. It is widely used for system administration, task
automation, and file manipulation.

## Usage

This directory contains the installation and configuration scripts for `sh`.

### Local and Global Version Management

The `sh` component works both as a **local version manager** (similar to tools like `rvm`, `nvm`,
`pyenv`, or `uv`) and can be seamlessly invoked from the global version manager via `libscript`.
This dual capability allows developers to manage specific versions per project locally or enforce
system-wide global configurations.

### Building Bigger Stacks

Beyond isolated provisioning, this component can be deeply integrated by `libscript` to build,
deploy, and manage larger stacks and complex applications. Whether you are scaffolding a CMS like
WordPress, a learning platform like Open edX, or a collaboration suite like Nextcloud, LibScript can
orchestrate `sh` alongside databases, web servers, and other services to form a cohesive,
reproducible stack.

You can install, start, stop, package, and uninstall sh using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install sh

./cli.sh install sh

./libscript.sh start sh
./cli.sh start sh

./libscript.sh stop sh
./cli.sh stop sh

./libscript.sh package-as docker sh
./cli.sh package-as docker sh

./libscript.sh uninstall sh
./cli.sh uninstall sh
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install sh

:: Local CLI
cli.cmd install sh

:: Start and Stop
libscript.cmd start sh
cli.cmd start sh

libscript.cmd stop sh
cli.cmd stop sh

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi sh
cli.cmd package-as msi sh

:: Uninstall
libscript.cmd uninstall sh
cli.cmd uninstall sh
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                                        | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `SH_INSTALL_METHOD` | How to install SH. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `SH_VERSION`        | Version of Shell Toolchain to install                                                                                                                              | `0.5.12`           |                  |
| `SH_DOWNLOAD_URL`   | Override URL for downloading sh binary or archive artifacts.                                                                                                       | `none`             |                  |
| `SH_RELEASES_URL`   | Override URL for querying sh available remote releases.                                                                                                            | `none`             |                  |

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
