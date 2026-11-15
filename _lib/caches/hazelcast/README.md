# hazelcast

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `hazelcast` component
(part of `_caches`) within the LibScript ecosystem. Distributed in-memory data grid and real-time
stream processing platform.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Hazelcast**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install hazelcast
libscript uninstall hazelcast
```

**Start / Stop (if configured as a background service):**

```sh
libscript start hazelcast
libscript stop hazelcast
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker hazelcast
```

_Note: On Unix environments, you can also use `./cli.sh install hazelcast`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HAZELCAST_INSTALL_METHOD` | How to install hazelcast. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `HAZELCAST_VERSION`        | Specific version of hazelcast to install.                                                                                                          | `latest`           | latest, lts      |
| `HAZELCAST_DOWNLOAD_URL`   | Override URL for downloading hazelcast binary or archive artifacts.                                                                                | `none`             |                  |
| `HAZELCAST_RELEASES_URL`   | Override URL for querying hazelcast available remote releases.                                                                                     | `none`             |                  |
| `HAZELCAST_LISTEN_PORT`    | TCP port on which the hazelcast service listens.                                                                                                   | `5701`             |                  |

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
