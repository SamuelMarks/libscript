# Windows Service Control Manager (sc.exe) Adapter (`_lib/init-systems/windows-scm/`)

## Overview

Windows Service Control Manager (SCM / sc.exe) native service lifecycle adapter and cross-platform
compatibility shim.

- **Tier**: `T2` (`_lib/init-systems/windows-scm/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `windows-scm`, `sc`, `sc.exe`
- **Target OS Whitelist (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the windows-scm service daemon
./libscript.sh install windows-scm latest
./libscript.sh start windows-scm
./libscript.sh status windows-scm
./libscript.sh logs windows-scm
./libscript.sh stop windows-scm
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install windows-scm latest
.\libscript.cmd start windows-scm
.\libscript.cmd status windows-scm
.\libscript.cmd stop windows-scm
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `WINDOWS_SCM_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default            | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WINDOWS_SCM_INSTALL_METHOD` | How to install windows-scm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `WINDOWS_SCM_VERSION`        | Specific version of windows-scm to install.                                                                                                          | `latest`           | latest, stable   |
| `WINDOWS_SCM_DOWNLOAD_URL`   | Override URL for downloading windows-scm binary or archive artifacts.                                                                                | `none`             |                  |
| `WINDOWS_SCM_RELEASES_URL`   | Override URL for querying windows-scm available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
