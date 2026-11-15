# vcpkg-tool

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `vcpkg-tool` component
(part of `_toolchains`) within the LibScript ecosystem. Native C++ command-line binary frontend for
the vcpkg package manager.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **vcpkg-tool**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install vcpkg-tool
libscript uninstall vcpkg-tool
```

**Start / Stop (if configured as a background service):**

```sh
libscript start vcpkg-tool
libscript stop vcpkg-tool
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker vcpkg-tool
```

_Note: On Unix environments, you can also use `./cli.sh install vcpkg-tool`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples   |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------ |
| `VCPKG_TOOL_INSTALL_METHOD` | How to install vcpkg-tool. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                    |
| `VCPKG_TOOL_VERSION`        | Specific version of vcpkg-tool to install.                                                                                                          | `latest`           | latest, 2024-12-09 |
| `VCPKG_TOOL_DOWNLOAD_URL`   | Override URL for downloading vcpkg-tool binary or archive artifacts.                                                                                | `none`             |                    |
| `VCPKG_TOOL_RELEASES_URL`   | Override URL for querying vcpkg-tool available remote releases.                                                                                     | `none`             |                    |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
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
