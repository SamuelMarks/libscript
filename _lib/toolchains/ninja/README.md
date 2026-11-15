# ninja

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `ninja` component (part of
`_toolchains`) within the LibScript ecosystem. A small build system with a focus on speed.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Ninja**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install ninja
libscript uninstall ninja
```

**Start / Stop (if configured as a background service):**

```sh
libscript start ninja
libscript stop ninja
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker ninja
```

_Note: On Unix environments, you can also use `./cli.sh install ninja`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples       |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------------- |
| `NINJA_INSTALL_METHOD` | How to install ninja. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                        |
| `NINJA_VERSION`        | Specific version of ninja to install.                                                                                                          | `latest`           | latest, 1.12.1, 1.11.1 |
| `NINJA_DOWNLOAD_URL`   | Override URL for downloading ninja binary or archive artifacts.                                                                                | `none`             |                        |
| `NINJA_RELEASES_URL`   | Override URL for querying ninja available remote releases.                                                                                     | `none`             |                        |

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
