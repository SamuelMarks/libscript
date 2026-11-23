# OpenRC Init System (`_lib/init-systems/openrc/`)

## Overview

Dependency-based `T2` init system and service supervisor used across Alpine Linux, Gentoo, Artix,
FreeBSD, and custom musl/glibc Linux From Scratch (`LFS`) distributions synthesized by `synthesis/`.

- **Tier**: `T2` (`_lib/init-systems/openrc/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `macos`

## Usage

```sh
# Stage OpenRC into a T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install openrc latest
./libscript.sh openrc --help
./_lib/init-systems/openrc/cli.sh test
```

```cmd
:: Query CLI or verify Option-A boundary behavior on Windows
.\libscript.cmd openrc --help
.\_lib\init-systems\openrc\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Installs `/sbin/openrc`, `/sbin/openrc-run`, and `/etc/runlevels/*`
  hierarchies into `LIBSCRIPT_TARGET_SYSROOT`, enabling `T1` `service-daemon` components and `T5`
  `workloads/schedulers/native.*` to emit declarative OpenRC init scripts offline during image
  synthesis.
- **Override Strategy**: Control acquisition via `OPENRC_INSTALL_METHOD` (`libscript_native` or
  `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OPENRC_INSTALL_METHOD` | Installation strategy for openrc: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `OPENRC_DOWNLOAD_URL`   | Override URL for downloading openrc binary or archive artifacts.                                                                                         | `none`             |                  |
| `OPENRC_RELEASES_URL`   | Override URL for querying openrc available remote releases.                                                                                              | `none`             |                  |
| `OPENRC_VERSION`        | Specific version of openrc to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
