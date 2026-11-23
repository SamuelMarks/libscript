# Kotlin Toolchain (`_lib/languages/kotlin/`)

## Overview

A modern programming language that makes developers happier.

- **Tier**: `T1` (`_lib/languages/kotlin/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `compiler`, `kotlin`, `jvm`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/kotlin/<version>)
./libscript.sh ls-remote kotlin
./libscript.sh install kotlin latest
./libscript.sh use kotlin latest
./libscript.sh which kotlin
./_lib/languages/kotlin/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote kotlin
.\libscript.cmd install kotlin latest
.\libscript.cmd use kotlin latest
.\libscript.cmd which kotlin
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/kotlin/<version>`
  (default `~/.libscript/kotlin/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `KOTLIN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KOTLIN_INSTALL_METHOD` | Installation strategy for kotlin: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `KOTLIN_VERSION`        | Version of Kotlin Toolchain to install                                                                                                                   | `1.9.20`           |                  |
| `KOTLIN_DOWNLOAD_URL`   | Override URL for downloading kotlin binary or archive artifacts.                                                                                         | `none`             |                  |
| `KOTLIN_RELEASES_URL`   | Override URL for querying kotlin available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
