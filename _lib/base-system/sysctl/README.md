# Kernel sysctl.d Parameter Manager (`_lib/base-system/sysctl/`)

## Overview

Declarative kernel runtime parameter manager (sysctl and /etc/sysctl.d drop-in configuration).

- **Tier**: `T2` (`_lib/base-system/sysctl/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `sysctl`, `sysctl-d`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `macos`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `sunos`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install sysctl latest
./libscript.sh sysctl --help
./_lib/base-system/sysctl/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd sysctl --help
.\_lib\base-system\sysctl\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `SYSCTL_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default                 | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---------------- |
| `SYSCTL_INSTALL_METHOD` | How to install sysctl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`      |                  |
| `SYSCTL_VERSION`        | Specific version of sysctl to install.                                                                                                          | `latest`                | latest, stable   |
| `SYSCTL_DOWNLOAD_URL`   | Override URL for downloading sysctl binary or archive artifacts.                                                                                | `none`                  |                  |
| `SYSCTL_RELEASES_URL`   | Override URL for querying sysctl available remote releases.                                                                                     | `none`                  |                  |
| `SYSCTL_PARAMS`         | Comma-separated list of kernel key=value parameters rendered into /etc/sysctl.d/<SYSCTL_CONF_NAME>.                                             | `net.ipv4.ip_forward=1` |                  |
| `SYSCTL_CONF_NAME`      | Drop-in filename written under /etc/sysctl.d/ when staging declarative kernel parameters.                                                       | `99-libscript.conf`     |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
