# Deno Runtime (`_lib/languages/deno/`)

## Overview

A secure runtime for JavaScript and TypeScript.

- **Tier**: `T1` (`_lib/languages/deno/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `javascript`, `typescript`, `deno`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/deno/<version>)
./libscript.sh ls-remote deno
./libscript.sh install deno latest
./libscript.sh use deno latest
./libscript.sh which deno
./_lib/languages/deno/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote deno
.\libscript.cmd install deno latest
.\libscript.cmd use deno latest
.\libscript.cmd which deno
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/deno/<version>`
  (default `~/.libscript/deno/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `DENO_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `DENO_INSTALL_METHOD` | Installation strategy for deno: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `DENO_VERSION`        | Version of Deno Runtime to install                                                                                                                     | `latest`           |                  |
| `DENO_DOWNLOAD_URL`   | Override URL for downloading deno binary or archive artifacts.                                                                                         | `none`             |                  |
| `DENO_RELEASES_URL`   | Override URL for querying deno available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
