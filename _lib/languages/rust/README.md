# Rust Toolchain (`_lib/languages/rust/`)

## Overview

A language empowering everyone to build reliable and efficient software.

- **Tier**: `T1` (`_lib/languages/rust/`)
- **Capabilities**: `userland-package`, `cross-toolchain`
- **Provides Virtual Capabilities**: `compiler`, `rust`, `cargo`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/rust/<version>)
./libscript.sh ls-remote rust
./libscript.sh install rust latest
./libscript.sh use rust latest
./libscript.sh which rust
./_lib/languages/rust/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote rust
.\libscript.cmd install rust latest
.\libscript.cmd use rust latest
.\libscript.cmd which rust
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/rust/<version>`
  (default `~/.libscript/rust/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `RUST_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default                                                                                            | Aliases/Examples                |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------- |
| `RUST_VERSION`        | Version of Rust demanded. Can be "nightly"                                                                                                             | "beta"                                                                                             | "stable" xor a specific version | `stable` | stable, beta, nightly |
| `RUST_INSTALL_METHOD` | Installation strategy for rust: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native`                                                                                 |                                 |
| `CARGO_NET_OFFLINE`   | Boolean flag ('true' or 'false') configuring Cargo to operate strictly offline.                                                                        | `false`                                                                                            |                                 |
| `CARGO_VENDOR_DIR`    | Directory path containing pre-vendored Cargo crates for offline builds.                                                                                | `none`                                                                                             |                                 |
| `RUST_DOWNLOAD_URL`   | Override URL for downloading rust binary or archive artifacts.                                                                                         | `none`                                                                                             |                                 |
| `RUST_RELEASES_URL`   | Override URL for querying rust available remote releases.                                                                                              | `none`                                                                                             |                                 |
| `RUST_RTOS_TARGETS`   | Comma-separated Rust no_std bare-metal targets registered via rustup target add for Zephyr and FreeRTOS.                                               | `thumbv7m-none-eabi,riscv32imac-unknown-none-elf,riscv64imac-unknown-none-elf,x86_64-unknown-none` |                                 |
| `RUST_TARGETS`        | Comma-separated cross-compilation target triples (e.g. wasm32-unknown-unknown,aarch64-unknown-none) installed into the isolated Rust toolchain.        | `none`                                                                                             |                                 |
| `RUST_COMPONENTS`     | Comma-separated optional Rust toolchain components (e.g. clippy,rustfmt,llvm-tools-preview,rust-src) installed into the isolated Rust toolchain.       | `none`                                                                                             |                                 |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
