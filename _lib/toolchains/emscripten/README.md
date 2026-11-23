# Emscripten (`_lib/toolchains/emscripten/`)

## Overview

LLVM-based C and C++ compiler toolchain targeting WebAssembly.

- **Tier**: `T1` (`_lib/toolchains/emscripten/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `emscripten`, `emcc`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/emscripten/<version>)
./libscript.sh ls-remote emscripten
./libscript.sh install emscripten latest
./libscript.sh use emscripten latest
./libscript.sh which emscripten
./_lib/toolchains/emscripten/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote emscripten
.\libscript.cmd install emscripten latest
.\libscript.cmd use emscripten latest
.\libscript.cmd which emscripten
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/emscripten/<version>`
  (default `~/.libscript/emscripten/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `EMSCRIPTEN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default  | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `EMSCRIPTEN_INSTALL_METHOD` | How to install emscripten. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `EMSCRIPTEN_VERSION`        | Specific version of emscripten to install.                                                                                                          | `latest` | latest, 3.1.74   |
| `EMSCRIPTEN_DOWNLOAD_URL`   | Override URL for downloading emscripten binary or archive artifacts.                                                                                | `none`   |                  |
| `EMSCRIPTEN_RELEASES_URL`   | Override URL for querying emscripten available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
