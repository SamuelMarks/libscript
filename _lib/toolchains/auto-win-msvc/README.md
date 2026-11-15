# auto-win-msvc

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `auto-win-msvc` component
(part of `_toolchains`) within the LibScript ecosystem. 91-module C89 POSIX/BSD/Linux/Solaris/macOS
compatibility header and static library layer for MSVC and OpenWatcom.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **auto-win-msvc C89
Compatibility Layer**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install auto-win-msvc
libscript uninstall auto-win-msvc
```

**Start / Stop (if configured as a background service):**

```sh
libscript start auto-win-msvc
libscript stop auto-win-msvc
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker auto-win-msvc
```

_Note: On Unix environments, you can also use `./cli.sh install auto-win-msvc`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                            | Default       | Aliases/Examples |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | ---------------- |
| `AUTO_WIN_MSVC_INSTALL_METHOD` | How to install auto-win-msvc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `AUTO_WIN_MSVC_VERSION`        | Specific version of auto-win-msvc to install.                                                                                                          | `latest`      | latest, lts      |
| `AUTO_WIN_MSVC_DOWNLOAD_URL`   | Override URL for downloading auto-win-msvc binary or archive artifacts.                                                                                | `none`        |                  |
| `AUTO_WIN_MSVC_RELEASES_URL`   | Override URL for querying auto-win-msvc available remote releases.                                                                                     | `none`        |                  |
| `AUTO_WIN_MSVC_REPO_DIR`       | Optional local checkout path for auto-win-msvc.                                                                                                        | ``            |                  |
| `AUTO_WIN_MSVC_USE_CDD_C`      | CMake toggle wiring cdd-c-transform into AutoWinMsvcTransform.cmake.                                                                                   | `ON`          |                  |

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
