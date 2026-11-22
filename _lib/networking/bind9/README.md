# bind9

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `bind9` component (part of
`_networking`) within the LibScript ecosystem. ISC BIND 9 (named) authoritative, recursive, and
DNSSEC-validating Domain Name System server and utilities.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **ISC BIND 9 DNS Server**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install bind9
libscript uninstall bind9
```

**Start / Stop (if configured as a background service):**

```sh
libscript start bind9
libscript stop bind9
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker bind9
```

_Note: On Unix environments, you can also use `./cli.sh install bind9`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BIND9_INSTALL_METHOD` | How to install bind9. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `BIND9_VERSION`        | Specific version of bind9 to install.                                                                                                          | `latest`           | latest, stable   |
| `BIND9_DOWNLOAD_URL`   | Override URL for downloading bind9 binary or archive artifacts.                                                                                | `none`             |                  |
| `BIND9_RELEASES_URL`   | Override URL for querying bind9 available remote releases.                                                                                     | `none`             |                  |
| `BIND9_LISTEN_PORT`    | TCP port on which the bind9 service listens.                                                                                                   | `53`               |                  |

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
