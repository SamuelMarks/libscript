# unikraft

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `unikraft` component (part
of `_orchestration`) within the LibScript ecosystem. Modular POSIX-compatible unikernel SDK and
KraftKit image builder targeting KVM, Firecracker, and Xen.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Unikraft (KraftKit)**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install unikraft
libscript uninstall unikraft
```

**Start / Stop (if configured as a background service):**

```sh
libscript start unikraft
libscript stop unikraft
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker unikraft
```

_Note: On Unix environments, you can also use `./cli.sh install unikraft`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `UNIKRAFT_INSTALL_METHOD` | How to install unikraft. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `UNIKRAFT_VERSION`        | Specific version of unikraft to install.                                                                                                          | `latest`           | latest, lts      |
| `UNIKRAFT_DOWNLOAD_URL`   | Override URL for downloading unikraft binary or archive artifacts.                                                                                | `none`             |                  |
| `UNIKRAFT_RELEASES_URL`   | Override URL for querying unikraft available remote releases.                                                                                     | `none`             |                  |

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
