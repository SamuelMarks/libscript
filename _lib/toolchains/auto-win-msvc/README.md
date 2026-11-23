# auto-win-msvc C89 Compatibility Layer (`_lib/toolchains/auto-win-msvc/`)

## Overview

91-module C89 POSIX/BSD/Linux/Solaris/macOS compatibility header and static library layer for MSVC
and OpenWatcom.

- **Tier**: `T1` (`_lib/toolchains/auto-win-msvc/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/auto-win-msvc/<version>)
./libscript.sh ls-remote auto-win-msvc
./libscript.sh install auto-win-msvc latest
./libscript.sh use auto-win-msvc latest
./libscript.sh which auto-win-msvc
./_lib/toolchains/auto-win-msvc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote auto-win-msvc
.\libscript.cmd install auto-win-msvc latest
.\libscript.cmd use auto-win-msvc latest
.\libscript.cmd which auto-win-msvc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/auto-win-msvc/<version>` (default `~/.libscript/auto-win-msvc/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `AUTO_WIN_MSVC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                            | Default       | Aliases/Examples |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | ---------------- |
| `AUTO_WIN_MSVC_INSTALL_METHOD` | How to install auto-win-msvc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `AUTO_WIN_MSVC_VERSION`        | Specific version of auto-win-msvc to install.                                                                                                          | `latest`      | latest, lts      |
| `AUTO_WIN_MSVC_DOWNLOAD_URL`   | Override URL for downloading auto-win-msvc binary or archive artifacts.                                                                                | `none`        |                  |
| `AUTO_WIN_MSVC_RELEASES_URL`   | Override URL for querying auto-win-msvc available remote releases.                                                                                     | `none`        |                  |
| `AUTO_WIN_MSVC_REPO_DIR`       | Optional local checkout path for auto-win-msvc.                                                                                                        | ``            |                  |
| `AUTO_WIN_MSVC_USE_CDD_C`      | CMake toggle wiring cdd-c-transform into AutoWinMsvcTransform.cmake.                                                                                   | `ON`          |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
