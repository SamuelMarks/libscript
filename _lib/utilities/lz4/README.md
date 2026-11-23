# LZ4 Lossless Compression Library & CLI (`_lib/utilities/lz4/`)

## Overview

Standalone version manager and custom-compiler source builder for LZ4 (pinned default 1.10.0) with
upstream make check/test verification.

- **Tier**: `T1` (`_lib/utilities/lz4/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lz4/<version>)
./libscript.sh ls-remote lz4
./libscript.sh install lz4 latest
./libscript.sh use lz4 latest
./libscript.sh which lz4
./_lib/utilities/lz4/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lz4
.\libscript.cmd install lz4 latest
.\libscript.cmd use lz4 latest
.\libscript.cmd which lz4
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lz4/<version>`
  (default `~/.libscript/lz4/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LZ4_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default       | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `LZ4_INSTALL_METHOD` | How to install lz4. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `LZ4_VERSION`        | Specific version of lz4 to install.                                                                                                          | `1.10.0`      | latest, lts      |
| `LZ4_DOWNLOAD_URL`   | Override URL for downloading lz4 binary or archive artifacts.                                                                                | `none`        |                  |
| `LZ4_RELEASES_URL`   | Override URL for querying lz4 available remote releases.                                                                                     | `none`        |                  |
| `LZ4_RUN_TESTS`      | Whether to execute the upstream LZ4 test suite (make check) after building from source.                                                      | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
