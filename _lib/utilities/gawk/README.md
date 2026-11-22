# gawk

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `gawk` component (part of
`_utilities`) within the LibScript ecosystem. Standalone GNU Awk 5.4+ pattern scanning and
processing language with dynamic C extension support.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **GNU Awk (gawk)**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install gawk
libscript uninstall gawk
```

**Start / Stop (if configured as a background service):**

```sh
libscript start gawk
libscript stop gawk
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker gawk
```

_Note: On Unix environments, you can also use `./cli.sh install gawk`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                                    | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `GAWK_INSTALL_METHOD` | How to install gawk. 'libscript_native' uses isolated version dirs (dos32 on MS-DOS, PE on Windows), 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GAWK_VERSION`        | Specific version of gawk to install (e.g., 5.4.60 on Windows/MS-DOS, 5.3.1 on POSIX, or latest).                                                                               | `latest`           | latest, lts      |
| `GAWK_DOWNLOAD_URL`   | Override URL for downloading gawk binary or archive artifacts.                                                                                                                 | `none`             |                  |
| `GAWK_RELEASES_URL`   | Override URL for querying gawk available remote releases.                                                                                                                      | `none`             |                  |

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
