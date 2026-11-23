# NSSM (Non-Sucking Service Manager) (`_lib/init-systems/nssm/`)

## Overview

Windows service wrapper and daemon supervisor for running native Win64 binaries (Waitress, Celery,
Caddy, Meilisearch) as resilient Windows Services.

- **Tier**: `T2` (`_lib/init-systems/nssm/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `nssm`, `init-system`

## Usage

```sh
# Install and manage the nssm service daemon
./libscript.sh install nssm latest
./libscript.sh start nssm
./libscript.sh status nssm
./libscript.sh logs nssm
./libscript.sh stop nssm
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install nssm latest
.\libscript.cmd start nssm
.\libscript.cmd status nssm
.\libscript.cmd stop nssm
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `NSSM_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                        | Default            | Aliases/Examples |
| --------------------- | ---------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NSSM_INSTALL_METHOD` | How to install nssm ('libscript_native' or 'system').                              | `libscript_native` |                  |
| `NSSM_VERSION`        | Specific version of nssm to install.                                               | `2.24`             |                  |
| `NSSM_INSTALL_DIR`    | Target directory for isolated nssm installation.                                   | `none`             |                  |
| `NSSM_OFFLINE`        | Flag (true/false or 1/0) indicating air-gapped offline installation mode for nssm. | `false`            |                  |
| `NSSM_DOWNLOAD_URL`   | Override URL for downloading nssm release zip archive.                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
