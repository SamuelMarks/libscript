# Unikraft (KraftKit) (`_lib/unikernels/unikraft/`)

## Overview

Modular POSIX-compatible unikernel SDK and KraftKit image builder targeting KVM, Firecracker, and
Xen.

- **Tier**: `T2` (`_lib/unikernels/unikraft/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `unikraft`, `kraft`, `unikernel-builder`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install unikraft latest
./libscript.sh unikraft --help
./_lib/unikernels/unikraft/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd unikraft --help
.\_lib\unikernels\unikraft\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `UNIKRAFT_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `UNIKRAFT_INSTALL_METHOD` | How to install unikraft. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `UNIKRAFT_VERSION`        | Specific version of unikraft to install.                                                                                                          | `latest`           | latest, lts      |
| `UNIKRAFT_DOWNLOAD_URL`   | Override URL for downloading unikraft binary or archive artifacts.                                                                                | `none`             |                  |
| `UNIKRAFT_RELEASES_URL`   | Override URL for querying unikraft available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
