# Tailscale Mesh VPN (`_lib/networking/tailscale/`)

## Overview

Tailscale zero-config WireGuard mesh VPN client and daemon (tailscale and tailscaled).

- **Tier**: `T2` (`_lib/networking/tailscale/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `tailscale`, `tailscaled`

## Usage

```sh
# Install and manage the tailscale service daemon
./libscript.sh install tailscale latest
./libscript.sh start tailscale
./libscript.sh status tailscale
./libscript.sh logs tailscale
./libscript.sh stop tailscale
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install tailscale latest
.\libscript.cmd start tailscale
.\libscript.cmd status tailscale
.\libscript.cmd stop tailscale
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `TAILSCALE_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TAILSCALE_INSTALL_METHOD` | How to install tailscale. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TAILSCALE_VERSION`        | Specific version of tailscale to install.                                                                                                          | `latest`           | latest, stable   |
| `TAILSCALE_DOWNLOAD_URL`   | Override URL for downloading tailscale binary or archive artifacts.                                                                                | `none`             |                  |
| `TAILSCALE_RELEASES_URL`   | Override URL for querying tailscale available remote releases.                                                                                     | `none`             |                  |
| `TAILSCALE_LISTEN_PORT`    | TCP port on which the tailscale service listens.                                                                                                   | `41641`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
