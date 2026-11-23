# Nanos Unikernel (Ops) (`_lib/unikernels/nanos/`)

## Overview

NanoVMs Ops CLI and Nanos unikernel image packager running unmodified ELF binaries on KVM, QEMU,
Xen, and cloud hypervisors.

- **Tier**: `T2` (`_lib/unikernels/nanos/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `nanos`, `ops`, `unikernel-builder`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install nanos latest
./libscript.sh nanos --help
./_lib/unikernels/nanos/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd nanos --help
.\_lib\unikernels\nanos\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `NANOS_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NANOS_INSTALL_METHOD` | How to install nanos. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `NANOS_VERSION`        | Specific version of nanos to install.                                                                                                          | `latest`           | latest, lts      |
| `NANOS_DOWNLOAD_URL`   | Override URL for downloading nanos binary or archive artifacts.                                                                                | `none`             |                  |
| `NANOS_RELEASES_URL`   | Override URL for querying nanos available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
