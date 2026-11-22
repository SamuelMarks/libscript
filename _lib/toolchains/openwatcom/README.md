# openwatcom

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openwatcom` component
(part of `_toolchains`) within the LibScript ecosystem. OpenWatcom v2 16/32-bit C/C++ cross-compiler
(wcl386, wlink, wstrip, DOS32A.EXE) targeting MS-DOS LE and Win32.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenWatcom v2 C/C++
Cross-Compiler**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install openwatcom
libscript uninstall openwatcom
```

**Start / Stop (if configured as a background service):**

```sh
libscript start openwatcom
libscript stop openwatcom
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker openwatcom
```

_Note: On Unix environments, you can also use `./cli.sh install openwatcom`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OPENWATCOM_INSTALL_METHOD` | How to install openwatcom. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OPENWATCOM_VERSION`        | Specific version of openwatcom to install.                                                                                                          | `2.0`              | latest, lts      |
| `OPENWATCOM_DOWNLOAD_URL`   | Override URL for downloading openwatcom binary or archive artifacts.                                                                                | `none`             |                  |
| `OPENWATCOM_RELEASES_URL`   | Override URL for querying openwatcom available remote releases.                                                                                     | `none`             |                  |
| `OPENWATCOM_ROOT`           | Override path for the WATCOM installation root containing binl64/binnt64/binosx and h headers.                                                      | ``                 |                  |

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
