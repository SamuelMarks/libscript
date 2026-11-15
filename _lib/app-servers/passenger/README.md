# passenger

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `passenger` component
(part of `_app-servers`) within the LibScript ecosystem. Polyglot web and application server
supporting Ruby, Node.js, Python, and Meteor workloads.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Phusion Passenger**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install passenger
libscript uninstall passenger
```

**Start / Stop (if configured as a background service):**

```sh
libscript start passenger
libscript stop passenger
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker passenger
```

_Note: On Unix environments, you can also use `./cli.sh install passenger`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PASSENGER_INSTALL_METHOD` | How to install passenger. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PASSENGER_VERSION`        | Specific version of passenger to install.                                                                                                          | `latest`           | latest, lts      |
| `PASSENGER_DOWNLOAD_URL`   | Override URL for downloading passenger binary or archive artifacts.                                                                                | `none`             |                  |
| `PASSENGER_RELEASES_URL`   | Override URL for querying passenger available remote releases.                                                                                     | `none`             |                  |
| `PASSENGER_LISTEN_PORT`    | TCP port on which the passenger service listens.                                                                                                   | `3000`             |                  |

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
