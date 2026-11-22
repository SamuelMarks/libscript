# juicefs

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `juicefs` component (part
of `_storage-layers`) within the LibScript ecosystem. High-performance cloud-native POSIX
distributed filesystem built on top of object storage and metadata engines.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **JuiceFS**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install juicefs
libscript uninstall juicefs
```

**Start / Stop (if configured as a background service):**

```sh
libscript start juicefs
libscript stop juicefs
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker juicefs
```

_Note: On Unix environments, you can also use `./cli.sh install juicefs`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `JUICEFS_INSTALL_METHOD` | How to install juicefs. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `JUICEFS_VERSION`        | Specific version of juicefs to install.                                                                                                          | `latest`           | latest, lts      |
| `JUICEFS_DOWNLOAD_URL`   | Override URL for downloading juicefs binary or archive artifacts.                                                                                | `none`             |                  |
| `JUICEFS_RELEASES_URL`   | Override URL for querying juicefs available remote releases.                                                                                     | `none`             |                  |
| `JUICEFS_LISTEN_PORT`    | TCP port on which the juicefs service listens.                                                                                                   | `9567`             |                  |

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
