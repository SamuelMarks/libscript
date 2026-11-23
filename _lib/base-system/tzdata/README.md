# IANA Time Zone Database (`_lib/base-system/tzdata/`)

## Overview

IANA Time Zone Database (tzdata) compiler and zone dumper utilities (zdump, zic) with declarative
/etc/localtime staging.

- **Tier**: `T2` (`_lib/base-system/tzdata/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `tzdata`, `zdump`, `zic`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install tzdata latest
./libscript.sh tzdata --help
./_lib/base-system/tzdata/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd tzdata --help
.\_lib\base-system\tzdata\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `TZDATA_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TZDATA_INSTALL_METHOD` | How to install tzdata. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TZDATA_VERSION`        | Specific version of tzdata to install.                                                                                                          | `latest`           | latest, stable   |
| `TZDATA_DOWNLOAD_URL`   | Override URL for downloading tzdata binary or archive artifacts.                                                                                | `none`             |                  |
| `TZDATA_RELEASES_URL`   | Override URL for querying tzdata available remote releases.                                                                                     | `none`             |                  |
| `TZDATA_TIMEZONE`       | IANA timezone identifier (e.g., UTC or America/New_York) staged into /etc/timezone and /etc/localtime.                                          | `UTC`              |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
