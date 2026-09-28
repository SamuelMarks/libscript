# FreeBSD Modular Distribution Substrate (`_lib/freebsd/distro/`)

## Overview

The `_lib/freebsd/distro/` directory houses modular assembly scripts for synthesizing tailored,
production-ready FreeBSD distributions. It implements flexible component selection across:

- **Base System Bootstrap**: Sysroot directory staging, release manifest validation, and extraction
  (`base.sh`, `base.cmd`).
- **Core System Configuration**: Loader configuration, rc.d configuration, fstab generation, and
  terminal lines (`config.sh`, `config.cmd`).
- **Package Management**: Official pkg(8) repository mirrors and configuration (`pkg.sh`,
  `pkg.cmd`).
- **User Accounts & Security**: User creation, groups (`wheel`, `operator`, `video`), `doas.conf`,
  `sudoers.d`, and SSH authorized keys (`users.sh`, `users.cmd`).
- **Init Systems**: Pluggable supervisors including `bsd-rc`, `openrc`, `runit`, `s6`, and `dinit`
  (`init.sh`, `init.cmd`).
- **Display Protocols & Drivers**: Wayland, X11, or headless modes with `drm-kmod` and devfs rules
  (`display.sh`, `display.cmd`).
- **Desktop Environments**: Sway, XFCE4, KDE Plasma 6, Openbox, Labwc, LXQt, and GNOME
  (`desktop.sh`, `desktop.cmd`).
- **Display Managers**: LightDM, SDDM, Greetd, and console login (`dm.sh`, `dm.cmd`).
- **Audio Subsystems**: Native FreeBSD OSS, PipeWire/WirePlumber, or none (`audio.sh`, `audio.cmd`).
- **Assembly Orchestrator**: JSON profile reader and module pipeline coordinator (`assemble.sh`,
  `assemble.cmd`).

## Usage

To assemble a distribution sysroot from a profile:

```sh
./_lib/freebsd/distro/assemble.sh profiles/freebsd/minimal-server.json build/freebsd-sysroot
```

On Windows Command Prompt:

```cmd
.\_lib\freebsd\distro\assemble.cmd profiles\freebsd\minimal-server.json build\freebsd-sysroot
```

## Profiles

Preset profiles are located in `profiles/freebsd/`:

- `minimal-server.json`: Headless server with bsd-rc and UFS2.
- `zfs-cloud.json`: Headless cloud instance with bsd-rc, ZFS root pool, and Vagrant user.
- `openrc-wayland-sway.json`: OpenRC supervisor, Wayland, Sway WM, seatd, and PipeWire.
- `desktop-xfce-x11.json`: bsd-rc supervisor, X11 Xorg, XFCE4, and LightDM.
- `plasma-wayland.json`: bsd-rc supervisor, Wayland, KDE Plasma 6, and SDDM.
- `hardened-runit.json`: Runit supervisor, minimal footprint, hardened base.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
