# wireguard

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `wireguard` component
(part of `_security`) within the LibScript ecosystem. Fast, modern, cryptographically opinionated
VPN tunnel configuration utilities (wg and wg-quick).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **WireGuard Tools**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install wireguard
libscript uninstall wireguard
```

**Start / Stop (if configured as a background service):**

```sh
libscript start wireguard
libscript stop wireguard
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker wireguard
```

_Note: On Unix environments, you can also use `./cli.sh install wireguard`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default  | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `WIREGUARD_INSTALL_METHOD` | How to install wireguard. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `WIREGUARD_VERSION`        | Specific version of wireguard to install.                                                                                                          | `latest` | latest, lts      |
| `WIREGUARD_DOWNLOAD_URL`   | Override URL for downloading wireguard binary or archive artifacts.                                                                                | `none`   |                  |
| `WIREGUARD_RELEASES_URL`   | Override URL for querying wireguard available remote releases.                                                                                     | `none`   |                  |
| `WIREGUARD_LISTEN_PORT`    | TCP port on which the wireguard service listens.                                                                                                   | `51820`  |                  |

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
