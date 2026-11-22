# Bun

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `bun` component (part of
`_toolchain`) within the LibScript ecosystem. This component is responsible for installing and
managing **Bun**, the fast all-in-one JavaScript runtime, bundler, transpiler, and package manager.

## Usage

This directory contains the installation and configuration scripts for `bun`. It is engineered to
operate both as a robust local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for
localized Bun environment management, and can be invoked seamlessly from the global version manager
`libscript`.

By leveraging this component, LibScript can use Bun as a high-performance building block to
provision and orchestrate much bigger stacks, such as WordPress, Open edX, Nextcloud, and modern
JavaScript-heavy web applications.

You can install, start, stop, package, and uninstall bun using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install bun

./cli.sh install bun

./libscript.sh start bun
./cli.sh start bun

./libscript.sh stop bun
./cli.sh stop bun

./libscript.sh package-as docker bun
./cli.sh package-as docker bun

./libscript.sh uninstall bun
./cli.sh uninstall bun
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install bun

:: Local CLI
cli.cmd install bun

:: Start and Stop
libscript.cmd start bun
cli.cmd start bun

libscript.cmd stop bun
cli.cmd stop bun

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi bun
cli.cmd package-as msi bun

:: Uninstall
libscript.cmd uninstall bun
cli.cmd uninstall bun
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BUN_VERSION`        | Version of Bun demanded. Can be a specific version number like 'bun-v1.1.0' or an alias.                                                                            | `latest`           | latest, canary   |
| `BUN_INSTALL_METHOD` | How to install BUN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `BUN_DOWNLOAD_URL`   | Override URL for downloading bun binary or archive artifacts.                                                                                                       | `none`             |                  |
| `BUN_RELEASES_URL`   | Override URL for querying bun available remote releases.                                                                                                            | `none`             |                  |

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
