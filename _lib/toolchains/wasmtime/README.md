# Wasmtime (`_lib/toolchains/wasmtime/`)

## Overview

A fast and secure runtime and CLI toolchain for WebAssembly.

- **Tier**: `T1` (`_lib/toolchains/wasmtime/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `wasmtime`, `wasm-runtime`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/wasmtime/<version>)
./libscript.sh ls-remote wasmtime
./libscript.sh install wasmtime latest
./libscript.sh use wasmtime latest
./libscript.sh which wasmtime
./_lib/toolchains/wasmtime/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote wasmtime
.\libscript.cmd install wasmtime latest
.\libscript.cmd use wasmtime latest
.\libscript.cmd which wasmtime
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/wasmtime/<version>`
  (default `~/.libscript/wasmtime/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `WASMTIME_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WASMTIME_INSTALL_METHOD` | How to install wasmtime. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `WASMTIME_VERSION`        | Specific version of wasmtime to install.                                                                                                          | `latest`           | latest, 28.0.0   |
| `WASMTIME_DOWNLOAD_URL`   | Override URL for downloading wasmtime binary or archive artifacts.                                                                                | `none`             |                  |
| `WASMTIME_RELEASES_URL`   | Override URL for querying wasmtime available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
