# mirage

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `mirage` component (part
of `_orchestration`) within the LibScript ecosystem. OCaml library operating system and Solo5
(hvt/spt) unikernel synthesizer.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **MirageOS Unikernel**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install mirage
libscript uninstall mirage
```

**Start / Stop (if configured as a background service):**

```sh
libscript start mirage
libscript stop mirage
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker mirage
```

_Note: On Unix environments, you can also use `./cli.sh install mirage`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default       | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `MIRAGE_INSTALL_METHOD` | How to install mirage. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `MIRAGE_VERSION`        | Specific version of mirage to install.                                                                                                          | `latest`      | latest, lts      |
| `MIRAGE_DOWNLOAD_URL`   | Override URL for downloading mirage binary or archive artifacts.                                                                                | `none`        |                  |
| `MIRAGE_RELEASES_URL`   | Override URL for querying mirage available remote releases.                                                                                     | `none`        |                  |

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
