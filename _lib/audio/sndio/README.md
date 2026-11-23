# OpenBSD sndio Audio & MIDI Framework (`_lib/audio/sndio/`)

## Overview

Lightweight OpenBSD audio and MIDI server daemon and library (sndiod, aucat, sndioctl).

- **Tier**: `T2` (`_lib/audio/sndio/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `sndio`, `sndiod`, `aucat`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install sndio latest
./libscript.sh sndio --help
./_lib/audio/sndio/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd sndio --help
.\_lib\audio\sndio\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `SNDIO_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SNDIO_INSTALL_METHOD` | How to install sndio. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SNDIO_VERSION`        | Specific version of sndio to install.                                                                                                          | `latest`           | latest, stable   |
| `SNDIO_DOWNLOAD_URL`   | Override URL for downloading sndio binary or archive artifacts.                                                                                | `none`             |                  |
| `SNDIO_RELEASES_URL`   | Override URL for querying sndio available remote releases.                                                                                     | `none`             |                  |
| `SNDIO_LISTEN_PORT`    | TCP port on which the sndio service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
