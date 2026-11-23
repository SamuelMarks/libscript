# Protocol Buffers (`_lib/toolchains/protobuf/`)

## Overview

Protocol Buffers data interchange compiler (protoc) and schema toolchain.

- **Tier**: `T1` (`_lib/toolchains/protobuf/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `protobuf`, `protoc`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/protobuf/<version>)
./libscript.sh ls-remote protobuf
./libscript.sh install protobuf latest
./libscript.sh use protobuf latest
./libscript.sh which protobuf
./_lib/toolchains/protobuf/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote protobuf
.\libscript.cmd install protobuf latest
.\libscript.cmd use protobuf latest
.\libscript.cmd which protobuf
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/protobuf/<version>`
  (default `~/.libscript/protobuf/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `PROTOBUF_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PROTOBUF_INSTALL_METHOD` | How to install protobuf. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PROTOBUF_VERSION`        | Specific version of protobuf to install.                                                                                                          | `latest`           | latest, 29.2     |
| `PROTOBUF_DOWNLOAD_URL`   | Override URL for downloading protobuf binary or archive artifacts.                                                                                | `none`             |                  |
| `PROTOBUF_RELEASES_URL`   | Override URL for querying protobuf available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
