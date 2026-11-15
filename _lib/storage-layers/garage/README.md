# garage

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `garage` component (part
of `_storage-layers`) within the LibScript ecosystem. Lightweight geo-distributed S3-compatible
object storage service designed for self-hosting.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Garage**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install garage
libscript uninstall garage
```

**Start / Stop (if configured as a background service):**

```sh
libscript start garage
libscript stop garage
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker garage
```

_Note: On Unix environments, you can also use `./cli.sh install garage`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GARAGE_INSTALL_METHOD` | How to install garage. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GARAGE_VERSION`        | Specific version of garage to install.                                                                                                          | `latest`           | latest, lts      |
| `GARAGE_DOWNLOAD_URL`   | Override URL for downloading garage binary or archive artifacts.                                                                                | `none`             |                  |
| `GARAGE_RELEASES_URL`   | Override URL for querying garage available remote releases.                                                                                     | `none`             |                  |
| `GARAGE_LISTEN_PORT`    | TCP port on which the garage service listens.                                                                                                   | `3900`             |                  |

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
