# freebsd-usr-bin

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `freebsd-usr-bin`
component (part of `_utilities`) within the LibScript ecosystem. FreeBSD usr.bin command-line
utilities ported natively to Windows (MSVC) and MS-DOS.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **FreeBSD usr.bin Suite**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install freebsd-usr-bin
libscript uninstall freebsd-usr-bin
```

**Start / Stop (if configured as a background service):**

```sh
libscript start freebsd-usr-bin
libscript stop freebsd-usr-bin
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker freebsd-usr-bin
```

_Note: On Unix environments, you can also use `./cli.sh install freebsd-usr-bin`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                                                       | Default            | Aliases/Examples |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FREEBSD_USR_BIN_INSTALL_METHOD` | How to install freebsd-usr-bin. 'libscript_native' installs isolated prebuilt binaries (dos32 on MS-DOS, PE on Windows), 'system' uses OS package manager, and 'from-source' compiles via CMake.  | `libscript_native` |                  |
| `FREEBSD_USR_BIN_VERSION`        | Specific version of freebsd-usr-bin to install (e.g., 15.0.0 or latest).                                                                                                                          | `latest`           | latest, lts      |
| `FREEBSD_USR_BIN_APPLET`         | Optional single FreeBSD usr.bin utility name (e.g. sed, grep, cut, tr, sort, uniq, wc, head, tail, xargs, find, cmp, diff, patch, bmake) to download and stage instead of the full suite archive. | `none`             |                  |
| `FREEBSD_USR_BIN_DOWNLOAD_URL`   | Override URL for downloading freebsd-usr-bin binary or archive artifacts.                                                                                                                         | `none`             |                  |
| `FREEBSD_USR_BIN_RELEASES_URL`   | Override URL for querying freebsd-usr-bin available remote releases.                                                                                                                              | `none`             |                  |

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
