# libvirt Virtualization API & Daemon (`_lib/virtualization/libvirt/`)

## Overview

Open-source virtualization management API, daemon (libvirtd / virtqemud), and CLI shell (virsh) for
QEMU/KVM, Xen, LXC, and Bhyve.

- **Tier**: `T1` (`_lib/virtualization/libvirt/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `libvirt`, `virsh`, `libvirtd`

## Usage

```sh
# Install and manage the libvirt service daemon
./libscript.sh install libvirt latest
./libscript.sh start libvirt
./libscript.sh status libvirt
./libscript.sh logs libvirt
./libscript.sh stop libvirt
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install libvirt latest
.\libscript.cmd start libvirt
.\libscript.cmd status libvirt
.\libscript.cmd stop libvirt
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/libvirt/<version>`
  (default `~/.libscript/libvirt/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `LIBVIRT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `LIBVIRT_INSTALL_METHOD` | How to install libvirt. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LIBVIRT_VERSION`        | Specific version of libvirt to install.                                                                                                          | `latest`           | latest, stable   |
| `LIBVIRT_DOWNLOAD_URL`   | Override URL for downloading libvirt binary or archive artifacts.                                                                                | `none`             |                  |
| `LIBVIRT_RELEASES_URL`   | Override URL for querying libvirt available remote releases.                                                                                     | `none`             |                  |
| `LIBVIRT_LISTEN_PORT`    | TCP port on which the libvirt service listens.                                                                                                   | `16509`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
