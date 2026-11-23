# Swift Toolchain (`_lib/languages/swift/`)

## Overview

A powerful and intuitive programming language for iOS, macOS, tvOS, and watchOS.

- **Tier**: `T1` (`_lib/languages/swift/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `swift`, `toolchain`
- **Target OS Exclusions (`manifest.json`)**: `alpine`, `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/swift/<version>)
./libscript.sh ls-remote swift
./libscript.sh install swift latest
./libscript.sh use swift latest
./libscript.sh which swift
./_lib/languages/swift/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote swift
.\libscript.cmd install swift latest
.\libscript.cmd use swift latest
.\libscript.cmd which swift
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/swift/<version>`
  (default `~/.libscript/swift/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SWIFT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SWIFT_INSTALL_METHOD` | Installation strategy for swift: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `SWIFT_VERSION`        | Version of Swift Toolchain to install                                                                                                                   | `5.10`             |                  |
| `SWIFT_DOWNLOAD_URL`   | Override URL for downloading swift binary or archive artifacts.                                                                                         | `none`             |                  |
| `SWIFT_RELEASES_URL`   | Override URL for querying swift available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
