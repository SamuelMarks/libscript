# OpenWatcom v2 C/C++ Cross-Compiler (`_lib/toolchains/openwatcom/`)

## Overview

OpenWatcom v2 16/32-bit C/C++ cross-compiler (wcl386, wlink, wstrip, DOS32A.EXE) targeting MS-DOS LE
and Win32.

- **Tier**: `T1` (`_lib/toolchains/openwatcom/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `openwatcom`, `wcl386`, `wlink`, `wstrip`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`, `windows`, `freebsd`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/openwatcom/<version>)
./libscript.sh ls-remote openwatcom
./libscript.sh install openwatcom latest
./libscript.sh use openwatcom latest
./libscript.sh which openwatcom
./_lib/toolchains/openwatcom/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote openwatcom
.\libscript.cmd install openwatcom latest
.\libscript.cmd use openwatcom latest
.\libscript.cmd which openwatcom
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/openwatcom/<version>`
  (default `~/.libscript/openwatcom/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENWATCOM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OPENWATCOM_INSTALL_METHOD` | How to install openwatcom. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OPENWATCOM_VERSION`        | Specific version of openwatcom to install.                                                                                                          | `2.0`              | latest, lts      |
| `OPENWATCOM_DOWNLOAD_URL`   | Override URL for downloading openwatcom binary or archive artifacts.                                                                                | `none`             |                  |
| `OPENWATCOM_RELEASES_URL`   | Override URL for querying openwatcom available remote releases.                                                                                     | `none`             |                  |
| `OPENWATCOM_ROOT`           | Override path for the WATCOM installation root containing binl64/binnt64/binosx and h headers.                                                      | ``                 |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
