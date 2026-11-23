# i3 Tiling Window Manager (`_lib/desktops/i3/`)

## Overview

Dynamic tiling X11 window manager (i3, i3-msg, i3bar) designed for keyboard-driven workflows.

- **Tier**: `T2` (`_lib/desktops/i3/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `i3`, `i3wm`, `i3-msg`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `macos`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install i3 latest
./libscript.sh i3 --help
./_lib/desktops/i3/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd i3 --help
.\_lib\desktops\i3\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `I3_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `I3_INSTALL_METHOD` | How to install i3. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `I3_VERSION`        | Specific version of i3 to install.                                                                                                          | `latest`           | latest, stable   |
| `I3_DOWNLOAD_URL`   | Override URL for downloading i3 binary or archive artifacts.                                                                                | `none`             |                  |
| `I3_RELEASES_URL`   | Override URL for querying i3 available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
