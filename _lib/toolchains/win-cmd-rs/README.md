# win-cmd-rs

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `win-cmd-rs` component
(part of `_toolchains`) within the LibScript ecosystem. Safe Rust Windows cmd.exe interpreter
(wincmd) and linear Packrat 50-rule linter / 4-pass CST rewriter (wincheck).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **win-cmd-rs Batch
Interpreter & Linter**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install win-cmd-rs
libscript uninstall win-cmd-rs
```

**Start / Stop (if configured as a background service):**

```sh
libscript start win-cmd-rs
libscript stop win-cmd-rs
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker win-cmd-rs
```

_Note: On Unix environments, you can also use `./cli.sh install win-cmd-rs`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                                                                              | Default                                                               | Aliases/Examples           |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | -------------------------- |
| `WIN_CMD_RS_INSTALL_METHOD` | How to install win-cmd-rs. 'libscript_native' downloads prebuilt GitHub Release binaries into isolated version directories, 'system' uses the OS package manager, and 'from-source' compiles with Cargo. | `libscript_native`                                                    |                            |
| `WIN_CMD_RS_VERSION`        | Specific version or alias of win-cmd-rs to install.                                                                                                                                                      | `latest`                                                              | latest, stable, lts, 0.0.1 |
| `WIN_CMD_RS_DOWNLOAD_URL`   | Override URL or template ({VERSION}, {RUST_TARGET}, {EXT}) for downloading win-cmd-rs release archives.                                                                                                  | `none`                                                                |                            |
| `WIN_CMD_RS_RELEASES_URL`   | Override URL for querying available remote win-cmd-rs GitHub releases.                                                                                                                                   | `https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases/latest` |                            |
| `WIN_CMD_RS_CHECKSUM`       | Optional explicit SHA-256 digest override for verifying custom win-cmd-rs release archives.                                                                                                              | `none`                                                                |                            |
| `WIN_CMD_RS_REPO_DIR`       | Optional local checkout path for compiling win-cmd-rs offline when using the from-source method.                                                                                                         | ``                                                                    |                            |

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
