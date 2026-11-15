# lxd

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `lxd` component (part of
`_orchestration`) within the LibScript ecosystem. Canonical LXD next-generation system container and
virtual machine manager daemon (lxd) and REST CLI client (lxc).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Canonical LXD System
Container & VM Manager**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install lxd
libscript uninstall lxd
```

**Start / Stop (if configured as a background service):**

```sh
libscript start lxd
libscript stop lxd
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker lxd
```

_Note: On Unix environments, you can also use `./cli.sh install lxd`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples    |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------- |
| `LXD_INSTALL_METHOD` | How to install lxd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                     |
| `LXD_VERSION`        | Specific version of lxd to install.                                                                                                          | `latest`           | latest, stable, lts |
| `LXD_DOWNLOAD_URL`   | Override URL for downloading lxd binary or archive artifacts.                                                                                | `none`             |                     |
| `LXD_RELEASES_URL`   | Override URL for querying lxd available remote releases.                                                                                     | `none`             |                     |
| `LXD_LISTEN_PORT`    | TCP port on which the lxd service listens.                                                                                                   | `8443`             |                     |

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
