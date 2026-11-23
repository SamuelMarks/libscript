# cargo-llvm-cov Rust Coverage Subcommand (`_lib/toolchains/cargo-llvm-cov/`)

## Overview

Cargo subcommand for LLVM source-based line, region, and branch code coverage JSON extraction.

- **Tier**: `T1` (`_lib/toolchains/cargo-llvm-cov/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/cargo-llvm-cov/<version>)
./libscript.sh ls-remote cargo-llvm-cov
./libscript.sh install cargo-llvm-cov latest
./libscript.sh use cargo-llvm-cov latest
./libscript.sh which cargo-llvm-cov
./_lib/toolchains/cargo-llvm-cov/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote cargo-llvm-cov
.\libscript.cmd install cargo-llvm-cov latest
.\libscript.cmd use cargo-llvm-cov latest
.\libscript.cmd which cargo-llvm-cov
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/cargo-llvm-cov/<version>` (default `~/.libscript/cargo-llvm-cov/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CARGO_LLVM_COV_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

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

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
