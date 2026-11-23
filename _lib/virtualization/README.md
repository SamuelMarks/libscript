# Hypervisors, MicroVMMonitors & Compatibility Layers (`_lib/virtualization/`)

## Overview

**Tier Scope**: `T1`

Hardware virtual machine monitors, lightweight microVMs, embedded SoC simulators, and binary
translation layers (`qemu`, `libvirt`, `firecracker`, `cloud-hypervisor`, `virtualbox`, `utm`,
`lima`, `multipass`, `renode`, `wine`, `wsl`).

Each subdirectory in `_lib/virtualization/` is an atomic, self-contained LibScript component
governed by its own `manifest.json` and `vars.schema.json`. Components in `_lib/virtualization/`
never cross-source sibling components directly; instead, they source `T0` helpers from
`engine/common/` and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5`
(`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh cloud-hypervisor --help
./libscript.sh install cloud-hypervisor latest
./_lib/virtualization/cloud-hypervisor/cli.sh test
```

```cmd
.\libscript.cmd cloud-hypervisor --help
.\libscript.cmd install cloud-hypervisor latest
.\_lib\virtualization\cloud-hypervisor\cli.cmd test
```

## Components (11)

<!-- BEGIN_COMPONENTS -->

- [`cloud-hypervisor`](./cloud-hypervisor/README.md) (`T1` — `userland-package`): KVM and MSHV
  focused virtual machine monitor
- [`firecracker`](./firecracker/README.md) (`T1` — `userland-package`): KVM-based microVM manager
  for secure multitenant containers
- [`libvirt`](./libvirt/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  virtualization management API, daemon (libvirtd / virtqemud), and CLI shell (virsh) for QEMU/KVM,
  Xen, LXC, and Bhyve.
- [`lima`](./lima/README.md) (`T1` — `userland-package`): Lima (limactl) Linux virtual machines with
  automatic file sharing, port forwarding, and containerd/Docker support on macOS and Linux.
- [`multipass`](./multipass/README.md) (`T1` — `userland-package`): Canonical Multipass lightweight
  Ubuntu VM orchestrator (multipass and multipassd) across Linux, macOS, and Windows.
- [`qemu`](./qemu/README.md) (`T1` — `userland-package`): A generic and open source machine emulator
  and virtualizer with KVM hardware acceleration support.
- [`renode`](./renode/README.md) (`T1` — `userland-package`): Portable headless
  hardware/MCU/wireless multi-node simulation framework for Zephyr and FreeRTOS across Linux, macOS,
  and Windows.
- [`utm`](./utm/README.md) (`T1` — `userland-package`): UTM (utmctl) QEMU and Apple
  Virtualization.framework virtual machine frontend and CLI controller for macOS.
- [`virtualbox`](./virtualbox/README.md) (`T1` — `userland-package`): Oracle VM VirtualBox
  hypervisor with Extension Pack support for x86/amd64 virtualization.
- [`wine`](./wine/README.md) (`T1` — `userland-package`): WINE 9+ Win32 runtime and wineserver
  daemon for unconfounded warm and cold baseline evaluations.
- [`wsl`](./wsl/README.md) (`T1` — `userland-package`): Microsoft Windows Subsystem for Linux
  (wsl.exe) distribution lifecycle and kernel manager.

<!-- END_COMPONENTS -->
