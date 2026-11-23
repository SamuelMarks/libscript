# BusyBox (`_lib/utilities/busybox/`)

## Overview

Multi-call UNIX command suite combining common POSIX utilities with native Windows (MSVC) builds via
SamuelMarks/busybox-windows.

- **Tier**: `T1` (`_lib/utilities/busybox/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `busybox`, `busybox-windows`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/busybox/<version>)
./libscript.sh ls-remote busybox
./libscript.sh install busybox latest
./libscript.sh use busybox latest
./libscript.sh which busybox
./_lib/utilities/busybox/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote busybox
.\libscript.cmd install busybox latest
.\libscript.cmd use busybox latest
.\libscript.cmd which busybox
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/busybox/<version>`
  (default `~/.libscript/busybox/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `BUSYBOX_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                                                                                                     | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BUSYBOX_INSTALL_METHOD` | How to install BusyBox. 'libscript_native' installs isolated prebuilt binaries (SamuelMarks/busybox-windows on Windows/MS-DOS, static musl on Linux), 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `BUSYBOX_VERSION`        | Specific version of busybox to install (e.g., 1.39.0 on Windows or latest).                                                                                                                                                     | `latest`           | latest, lts      |
| `BUSYBOX_DOWNLOAD_URL`   | Override URL for downloading busybox binary or archive artifacts.                                                                                                                                                               | `none`             |                  |
| `BUSYBOX_RELEASES_URL`   | Override URL for querying busybox available remote releases.                                                                                                                                                                    | `none`             |                  |
| `BUSYBOX_INSTALL_SHIMS`  | When set to '1', materializes per-applet hardlinks or .bat/.exe trampolines in bin/ when freebsd-usr-bin is not installed.                                                                                                      | `0`                |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
