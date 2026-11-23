# Dart SDK (`_lib/languages/dart/`)

## Overview

Client-optimized language and SDK for fast multi-platform applications.

- **Tier**: `T1` (`_lib/languages/dart/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/dart/<version>)
./libscript.sh ls-remote dart
./libscript.sh install dart latest
./libscript.sh use dart latest
./libscript.sh which dart
./_lib/languages/dart/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote dart
.\libscript.cmd install dart latest
.\libscript.cmd use dart latest
.\libscript.cmd which dart
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/dart/<version>`
  (default `~/.libscript/dart/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `DART_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DART_INSTALL_METHOD` | How to install dart. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `DART_VERSION`        | Specific version of dart to install.                                                                                                          | `latest`           | latest, lts      |
| `DART_DOWNLOAD_URL`   | Override URL for downloading dart binary or archive artifacts.                                                                                | `none`             |                  |
| `DART_RELEASES_URL`   | Override URL for querying dart available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
