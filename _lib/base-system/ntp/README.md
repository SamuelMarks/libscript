# ntp

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `ntp` component (part of
`_base-system`) within the LibScript ecosystem. Reference Network Time Protocol (NTP) clock
synchronization daemon (ntpd) and query tools.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Network Time Protocol
Daemon (ntpd)**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install ntp
libscript uninstall ntp
```

**Start / Stop (if configured as a background service):**

```sh
libscript start ntp
libscript stop ntp
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker ntp
```

_Note: On Unix environments, you can also use `./cli.sh install ntp`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NTP_INSTALL_METHOD` | How to install ntp. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `NTP_VERSION`        | Specific version of ntp to install.                                                                                                          | `latest`           | latest, stable   |
| `NTP_DOWNLOAD_URL`   | Override URL for downloading ntp binary or archive artifacts.                                                                                | `none`             |                  |
| `NTP_RELEASES_URL`   | Override URL for querying ntp available remote releases.                                                                                     | `none`             |                  |
| `NTP_LISTEN_PORT`    | TCP port on which the ntp service listens.                                                                                                   | `123`              |                  |

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
