# Bear Compilation Database Generator (compile_commands.json) (`_lib/toolchains/bear/`)

## Overview

Standalone version manager and installer for Build EAR (bear), generating Clang JSON compilation
databases (compile_commands.json) for Make and Kbuild projects.

- **Tier**: `T1` (`_lib/toolchains/bear/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `bear`, `compilation-database`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/bear/<version>)
./libscript.sh ls-remote bear
./libscript.sh install bear latest
./libscript.sh use bear latest
./libscript.sh which bear
./_lib/toolchains/bear/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote bear
.\libscript.cmd install bear latest
.\libscript.cmd use bear latest
.\libscript.cmd which bear
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/bear/<version>`
  (default `~/.libscript/bear/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `BEAR_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `BEAR_INSTALL_METHOD` | How to install bear. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `BEAR_VERSION`        | Specific version of bear to install.                                                                                                          | `3.1.5`  | latest, lts      |
| `BEAR_DOWNLOAD_URL`   | Override URL for downloading bear binary or archive artifacts.                                                                                | `none`   |                  |
| `BEAR_RELEASES_URL`   | Override URL for querying bear available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
