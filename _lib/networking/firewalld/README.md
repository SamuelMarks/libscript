# firewalld

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `firewalld` component
(part of `_networking`) within the LibScript ecosystem. Dynamically managed Linux firewall daemon
(firewalld and firewall-cmd) supporting network/firewall zones over nftables and iptables.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Firewalld Dynamic Firewall
Daemon**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install firewalld
libscript uninstall firewalld
```

**Start / Stop (if configured as a background service):**

```sh
libscript start firewalld
libscript stop firewalld
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker firewalld
```

_Note: On Unix environments, you can also use `./cli.sh install firewalld`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FIREWALLD_INSTALL_METHOD` | How to install firewalld. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FIREWALLD_VERSION`        | Specific version of firewalld to install.                                                                                                          | `latest`           | latest, stable   |
| `FIREWALLD_DOWNLOAD_URL`   | Override URL for downloading firewalld binary or archive artifacts.                                                                                | `none`             |                  |
| `FIREWALLD_RELEASES_URL`   | Override URL for querying firewalld available remote releases.                                                                                     | `none`             |                  |
| `FIREWALLD_LISTEN_PORT`    | TCP port on which the firewalld service listens.                                                                                                   | `8080`             |                  |

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
