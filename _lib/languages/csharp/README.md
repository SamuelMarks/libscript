# C# Toolchain (`_lib/languages/csharp/`)

## Overview

C# compiler and .NET runtime.

- **Tier**: `T1` (`_lib/languages/csharp/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `compiler`, `c#`, `csharp`, `dotnet`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/csharp/<version>)
./libscript.sh ls-remote csharp
./libscript.sh install csharp latest
./libscript.sh use csharp latest
./libscript.sh which csharp
./_lib/languages/csharp/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote csharp
.\libscript.cmd install csharp latest
.\libscript.cmd use csharp latest
.\libscript.cmd which csharp
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/csharp/<version>`
  (default `~/.libscript/csharp/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CSHARP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CSHARP_INSTALL_METHOD` | Installation strategy for csharp: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `CSHARP_VERSION`        | Version of C# Toolchain to install                                                                                                                       | `latest`           |                  |
| `CSHARP_DOWNLOAD_URL`   | Override URL for downloading csharp binary or archive artifacts.                                                                                         | `none`             |                  |
| `CSHARP_RELEASES_URL`   | Override URL for querying csharp available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
