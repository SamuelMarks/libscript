# Systemd (`_lib/init-systems/systemd/`)

## Overview

systemd.

- **Tier**: `T2` (`_lib/init-systems/systemd/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Target OS Whitelist (`manifest.json`)**: `linux`
- **Target OS Exclusions (`manifest.json`)**: `freebsd`, `windows`, `alpine`, `darwin`, `sunos`

## Usage

```sh
# Install and manage the systemd service daemon
./libscript.sh install systemd latest
./libscript.sh start systemd
./libscript.sh status systemd
./libscript.sh logs systemd
./libscript.sh stop systemd
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install systemd latest
.\libscript.cmd start systemd
.\libscript.cmd status systemd
.\libscript.cmd stop systemd
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `SYSTEMD_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                               | Default            | Aliases/Examples |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SYSTEMD_EXEC_START`     | Executor                                                                                                                                                  | `none`             |                  |
| `SYSTEMD_WORKING_DIR`    | Working directory that `EXEC_START` will be run from                                                                                                      | `none`             |                  |
| `SYSTEMD_ENV`            | Optional additional properties as key/value pairs                                                                                                         | `none`             |                  |
| `SYSTEMD_INSTALL_METHOD` | Installation strategy for systemd: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `SYSTEMD_DOWNLOAD_URL`   | Override URL for downloading systemd binary or archive artifacts.                                                                                         | `none`             |                  |
| `SYSTEMD_RELEASES_URL`   | Override URL for querying systemd available remote releases.                                                                                              | `none`             |                  |
| `SYSTEMD_VERSION`        | Specific version of systemd to install (e.g., latest, lts, or exact version).                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
