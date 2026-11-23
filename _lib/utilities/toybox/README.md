# Toybox (`_lib/utilities/toybox/`)

## Overview

All-in-one BSD-licensed POSIX, Windows native (MSVC), and MS-DOS (dos32) command-line utility suite
via SamuelMarks/toybox-windows.

- **Tier**: `T1` (`_lib/utilities/toybox/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `toybox`, `toybox-windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/toybox/<version>)
./libscript.sh ls-remote toybox
./libscript.sh install toybox latest
./libscript.sh use toybox latest
./libscript.sh which toybox
./_lib/utilities/toybox/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote toybox
.\libscript.cmd install toybox latest
.\libscript.cmd use toybox latest
.\libscript.cmd which toybox
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/toybox/<version>`
  (default `~/.libscript/toybox/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TOYBOX_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                                                       | Default            | Aliases/Examples |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TOYBOX_INSTALL_METHOD` | How to install toybox. 'libscript_native' uses isolated version dirs (dos32 on MS-DOS, PE on Windows, static on Linux), 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TOYBOX_VERSION`        | Specific version of toybox to install (e.g., 0.8.15 on Windows/MS-DOS or latest).                                                                                                                 | `latest`           | latest, lts      |
| `TOYBOX_DOWNLOAD_URL`   | Override URL for downloading toybox binary or archive artifacts.                                                                                                                                  | `none`             |                  |
| `TOYBOX_RELEASES_URL`   | Override URL for querying toybox available remote releases.                                                                                                                                       | `none`             |                  |
| `TOYBOX_INSTALL_SHIMS`  | When set to '1', materializes per-applet hardlinks or .bat/.exe trampolines in bin/ when freebsd-usr-bin is not installed.                                                                        | `0`                |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
