# illumos/Solaris Service Management Facility (SMF) (`_lib/init-systems/smf/`)

## Overview

illumos and Solaris Service Management Facility (SMF) manifest and service control adapter (svcadm,
svccfg, svcs).

- **Tier**: `T2` (`_lib/init-systems/smf/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `smf`, `svcadm`, `svccfg`
- **Target OS Whitelist (`manifest.json`)**: `sunos`, `illumos`, `solaris`

## Usage

```sh
# Install and manage the smf service daemon
./libscript.sh install smf latest
./libscript.sh start smf
./libscript.sh status smf
./libscript.sh logs smf
./libscript.sh stop smf
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install smf latest
.\libscript.cmd start smf
.\libscript.cmd status smf
.\libscript.cmd stop smf
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `SMF_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SMF_INSTALL_METHOD` | How to install smf. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SMF_VERSION`        | Specific version of smf to install.                                                                                                          | `latest`           | latest, stable   |
| `SMF_DOWNLOAD_URL`   | Override URL for downloading smf binary or archive artifacts.                                                                                | `none`             |                  |
| `SMF_RELEASES_URL`   | Override URL for querying smf available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
