# Tier 3 (`T3`) Curated OS, Unikernel & RTOS Synthesis Profiles (`synthesis/profiles/`)

## Overview

`synthesis/profiles/` contains declarative JSON profiles conforming to
`synthesis/schemas/os-config.schema.json` and `synthesis/schemas/execution-plan*.schema.json`.
Profiles are consumed by `./libscript.sh config os --profile=<name>`,
`engine/solver/resolve_stack.{sh,cmd}`, and `./libscript.sh package-as <format>`.

## Profile Families

- **`linux/`**: Minimal headless `musl`, standard `glibc` servers, Alpine/Debian/Red Hat-style
  distributions, Wayland/X11 desktops (`sway`, `hyprland`, `kde-plasma`, `xfce`), and multi-compiler
  Linux kernel profiles (`gcc`, `clang`, `tcc`, `edgcpp`, `custom-cc`).
- **`lfs/`**: Multi-stage Linux From Scratch profiles pairing `glibc` or `musl` with `systemd`,
  `openrc`, `runit`, `s6`, `dinit`, or `sysvinit` and Wayland/X11 desktops.
- **`freebsd/`**: FreeBSD 15.x minimal/standard ZFS servers, hardened `runit`, and `sway` / `plasma`
  / `xfce` graphical workstations.
- **`illumos/`**: illumos / OmniOS ZFS servers, `pkgsrc` developer workstations, and `xfce` / `mate`
  / retro `cde` desktops.
- **`reactos/`**: ReactOS `i686` and `x86_64` profiles (`minimal-headless-i686`,
  `desktop-classic-i686`, `developer-win32-i686`, `btrfs-appliance-i686`, `nightly-x86_64`).
- **`unikernel/`** (including `unikernel/openedx/`): Single-address-space OSv, Nanos, MirageOS,
  Rumprun, and Unikraft profiles plus the 8-appliance Open edX unikernel pod profiles.
- **`rtos/`**: Zephyr RTOS and FreeRTOS profiles for ARM Cortex-M, RISC-V 64, QEMU x86_64, WAMR
  WebAssembly edge appliances, and MCUboot-signed firmware.
- **`cloud/`**, **`containers/`**, **`hypervisor/`**: AWS AMI, Azure Gen2 VHD, GCP GCE, OCI/Docker,
  Firecracker microVM, Proxmox, VMware ESXi, and QEMU `cloud-init` base profiles.

## Usage

```sh
./libscript.sh config os --profile=linux-desktop-sway-wayland --export=os.json
./libscript.sh config os --validate=synthesis/profiles/freebsd/freebsd-server-standard.json
```
