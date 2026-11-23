# Rumprun Unikernel (`_lib/unikernels/rumprun/`)

## Overview

NetBSD rump kernel unikernel cross-toolchain and rumpbake image baker targeting KVM/VirtIO
(hw_virtio) and Xen.

- **Tier**: `T2` (`_lib/unikernels/rumprun/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `rumprun`, `rumpbake`, `unikernel-builder`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install rumprun latest
./libscript.sh rumprun --help
./_lib/unikernels/rumprun/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd rumprun --help
.\_lib\unikernels\rumprun\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `RUMPRUN_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default       | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------- | ---------------- |
| `RUMPRUN_INSTALL_METHOD` | How to install rumprun. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `RUMPRUN_VERSION`        | Specific version of rumprun to install.                                                                                                          | `latest`      | latest, lts      |
| `RUMPRUN_DOWNLOAD_URL`   | Override URL for downloading rumprun binary or archive artifacts.                                                                                | `none`        |                  |
| `RUMPRUN_RELEASES_URL`   | Override URL for querying rumprun available remote releases.                                                                                     | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
