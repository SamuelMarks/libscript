# OSv Unikernel (Capstan) (`_lib/unikernels/osv/`)

## Overview

OSv cloud unikernel runtime and Capstan image builder with ZFS, ROFS, and unmodified Linux PIE
shared-object support.

- **Tier**: `T2` (`_lib/unikernels/osv/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `osv`, `capstan`, `unikernel-builder`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install osv latest
./libscript.sh osv --help
./_lib/unikernels/osv/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd osv --help
.\_lib\unikernels\osv\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `OSV_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OSV_INSTALL_METHOD` | How to install osv. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OSV_VERSION`        | Specific version of osv to install.                                                                                                          | `latest`           | latest, lts      |
| `OSV_DOWNLOAD_URL`   | Override URL for downloading osv binary or archive artifacts.                                                                                | `none`             |                  |
| `OSV_RELEASES_URL`   | Override URL for querying osv available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
