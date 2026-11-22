# lxc

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `lxc` component (part of
`_orchestration`) within the LibScript ecosystem. Low-level Linux Containers userspace tools and
library (lxc-create, lxc-start, lxc-ls, lxc-attach) over kernel namespaces and cgroups.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Linux Containers (LXC)
Userspace Tools**. It is designed to be executed via the global `libscript.sh` router or directly
via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install lxc
libscript uninstall lxc
```

**Start / Stop (if configured as a background service):**

```sh
libscript start lxc
libscript stop lxc
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker lxc
```

_Note: On Unix environments, you can also use `./cli.sh install lxc`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples    |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------- |
| `LXC_INSTALL_METHOD` | How to install lxc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                     |
| `LXC_VERSION`        | Specific version of lxc to install.                                                                                                          | `latest`           | latest, stable, lts |
| `LXC_DOWNLOAD_URL`   | Override URL for downloading lxc binary or archive artifacts.                                                                                | `none`             |                     |
| `LXC_RELEASES_URL`   | Override URL for querying lxc available remote releases.                                                                                     | `none`             |                     |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
