# frr

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `frr` component (part of
`_networking`) within the LibScript ecosystem. FRRouting IP routing protocol suite implementing BGP,
OSPF, RIP, IS-IS, PIM, LDP, BFD, Babel, and EVPN (vtysh, zebra, bgpd, ospfd).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **FRRouting (FRR) Routing
Suite**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install frr
libscript uninstall frr
```

**Start / Stop (if configured as a background service):**

```sh
libscript start frr
libscript stop frr
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker frr
```

_Note: On Unix environments, you can also use `./cli.sh install frr`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FRR_INSTALL_METHOD` | How to install frr. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FRR_VERSION`        | Specific version of frr to install.                                                                                                          | `latest`           | latest, stable   |
| `FRR_DOWNLOAD_URL`   | Override URL for downloading frr binary or archive artifacts.                                                                                | `none`             |                  |
| `FRR_RELEASES_URL`   | Override URL for querying frr available remote releases.                                                                                     | `none`             |                  |
| `FRR_LISTEN_PORT`    | TCP port on which the frr service listens.                                                                                                   | `179`              |                  |

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
