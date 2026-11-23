# POSIX & glibc System Locales (`_lib/base-system/locales/`)

## Overview

POSIX and GNU C Library (glibc) system locale definition compiler (localedef / locale-gen) and
declarative locale staging.

- **Tier**: `T2` (`_lib/base-system/locales/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `locales`, `localedef`, `locale-gen`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`,
  `macos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install locales latest
./libscript.sh locales --help
./_lib/base-system/locales/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd locales --help
.\_lib\base-system\locales\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `LOCALES_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default                           | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- | ---------------- |
| `LOCALES_INSTALL_METHOD` | How to install locales. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`                |                  |
| `LOCALES_VERSION`        | Specific version of locales to install.                                                                                                          | `latest`                          | latest, stable   |
| `LOCALES_DOWNLOAD_URL`   | Override URL for downloading locales binary or archive artifacts.                                                                                | `none`                            |                  |
| `LOCALES_RELEASES_URL`   | Override URL for querying locales available remote releases.                                                                                     | `none`                            |                  |
| `LOCALES_DEFAULT`        | Default LANG system locale staged into /etc/locale.conf when provisioning a target sysroot.                                                      | `en_US.UTF-8`                     |                  |
| `LOCALES_LIST`           | Comma-separated list of locale entries staged into /etc/locale.gen when provisioning a target sysroot.                                           | `en_US.UTF-8 UTF-8,C.UTF-8 UTF-8` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
