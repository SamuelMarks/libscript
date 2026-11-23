# FreeBSD usr.bin Suite (`_lib/utilities/freebsd-usr-bin/`)

## Overview

FreeBSD usr.bin command-line utilities (~200 POSIX tools including sed, grep, cut, tr, sort, uniq,
wc, head, tail, xargs, find, diff, patch, bmake) ported natively to Windows (MSVC) and MS-DOS
(dos32).

- **Tier**: `T1` (`_lib/utilities/freebsd-usr-bin/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `freebsd-usr-bin`, `freebsd-usr-bin-windows`, `sed`, `grep`,
  `cut`, `tr`, `sort`, `uniq`, `wc`, `head`, `tail`, `xargs`, `find`, `cmp`, `diff`, `patch`,
  `bmake`, `bsdtar`, `bsdunzip`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/freebsd-usr-bin/<version>)
./libscript.sh ls-remote freebsd-usr-bin
./libscript.sh install freebsd-usr-bin latest
./libscript.sh use freebsd-usr-bin latest
./libscript.sh which freebsd-usr-bin
./_lib/utilities/freebsd-usr-bin/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote freebsd-usr-bin
.\libscript.cmd install freebsd-usr-bin latest
.\libscript.cmd use freebsd-usr-bin latest
.\libscript.cmd which freebsd-usr-bin
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/freebsd-usr-bin/<version>` (default `~/.libscript/freebsd-usr-bin/<version>`)
  and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FREEBSD_USR_BIN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                                                       | Default            | Aliases/Examples |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FREEBSD_USR_BIN_INSTALL_METHOD` | How to install freebsd-usr-bin. 'libscript_native' installs isolated prebuilt binaries (dos32 on MS-DOS, PE on Windows), 'system' uses OS package manager, and 'from-source' compiles via CMake.  | `libscript_native` |                  |
| `FREEBSD_USR_BIN_VERSION`        | Specific version of freebsd-usr-bin to install (e.g., 15.0.0 or latest).                                                                                                                          | `latest`           | latest, lts      |
| `FREEBSD_USR_BIN_APPLET`         | Optional single FreeBSD usr.bin utility name (e.g. sed, grep, cut, tr, sort, uniq, wc, head, tail, xargs, find, cmp, diff, patch, bmake) to download and stage instead of the full suite archive. | `none`             |                  |
| `FREEBSD_USR_BIN_DOWNLOAD_URL`   | Override URL for downloading freebsd-usr-bin binary or archive artifacts.                                                                                                                         | `none`             |                  |
| `FREEBSD_USR_BIN_RELEASES_URL`   | Override URL for querying freebsd-usr-bin available remote releases.                                                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
