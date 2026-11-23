# V (Vlang) (`_lib/languages/vlang/`)

## Overview

Simple, fast, safe, compiled systems programming language (v) with rapid C/native compilation.

- **Tier**: `T1` (`_lib/languages/vlang/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `vlang`, `v`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/vlang/<version>)
./libscript.sh ls-remote vlang
./libscript.sh install vlang latest
./libscript.sh use vlang latest
./libscript.sh which vlang
./_lib/languages/vlang/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote vlang
.\libscript.cmd install vlang latest
.\libscript.cmd use vlang latest
.\libscript.cmd which vlang
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/vlang/<version>`
  (default `~/.libscript/vlang/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `VLANG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `VLANG_INSTALL_METHOD` | How to install vlang. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `VLANG_VERSION`        | Specific version of vlang to install.                                                                                                          | `latest`           | latest, lts      |
| `VLANG_DOWNLOAD_URL`   | Override URL for downloading vlang binary or archive artifacts.                                                                                | `none`             |                  |
| `VLANG_RELEASES_URL`   | Override URL for querying vlang available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
