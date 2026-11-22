# cargo-llvm-cov

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `cargo-llvm-cov` component
(part of `_toolchains`) within the LibScript ecosystem. Cargo subcommand for LLVM source-based line,
region, and branch code coverage JSON extraction.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **cargo-llvm-cov Rust
Coverage Subcommand**. It is designed to be executed via the global `libscript.sh` router or
directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install cargo-llvm-cov
libscript uninstall cargo-llvm-cov
```

**Start / Stop (if configured as a background service):**

```sh
libscript start cargo-llvm-cov
libscript stop cargo-llvm-cov
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker cargo-llvm-cov
```

_Note: On Unix environments, you can also use `./cli.sh install cargo-llvm-cov`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                             | Default            | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CARGO_LLVM_COV_INSTALL_METHOD` | How to install cargo-llvm-cov. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CARGO_LLVM_COV_VERSION`        | Specific version of cargo-llvm-cov to install.                                                                                                          | `0.6.16`           | latest, lts      |
| `CARGO_LLVM_COV_DOWNLOAD_URL`   | Override URL for downloading cargo-llvm-cov binary or archive artifacts.                                                                                | `none`             |                  |
| `CARGO_LLVM_COV_RELEASES_URL`   | Override URL for querying cargo-llvm-cov available remote releases.                                                                                     | `none`             |                  |

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
