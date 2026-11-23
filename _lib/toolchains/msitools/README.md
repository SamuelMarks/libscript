# GNOME msitools (wixl) (`_lib/toolchains/msitools/`)

## Overview

GNOME msitools suite providing wixl, msiinfo, msibuild, msidump, and msiextract for MSI authoring
baselines.

- **Tier**: `T1` (`_lib/toolchains/msitools/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `msitools`, `wixl`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`, `freebsd`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/msitools/<version>)
./libscript.sh ls-remote msitools
./libscript.sh install msitools latest
./libscript.sh use msitools latest
./libscript.sh which msitools
./_lib/toolchains/msitools/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote msitools
.\libscript.cmd install msitools latest
.\libscript.cmd use msitools latest
.\libscript.cmd which msitools
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/msitools/<version>`
  (default `~/.libscript/msitools/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `MSITOOLS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `MSITOOLS_INSTALL_METHOD` | How to install msitools. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `MSITOOLS_VERSION`        | Specific version of msitools to install.                                                                                                          | `0.106`  | latest, lts      |
| `MSITOOLS_DOWNLOAD_URL`   | Override URL for downloading msitools binary or archive artifacts.                                                                                | `none`   |                  |
| `MSITOOLS_RELEASES_URL`   | Override URL for querying msitools available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
