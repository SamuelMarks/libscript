# LibScript System Profiles

## Overview

Contains declarative JSON blueprint specifications defining complete operating system profiles,
microVM appliances, desktop environments, and server images orchestrated by LibScript.

## Available Profiles

### Linux From Scratch (LFS) Modular Appliances

- `lfs-minimal-headless.json`: Minimal headless LFS appliance with OpenRC supervisor and
  busybox/coreutils.
- `lfs-sysvinit-x11-openbox.json`: Lightweight desktop LFS appliance with SysVinit, X11, Openbox
  window manager, and LightDM.
- `lfs-openrc-wayland-sway.json`: Workstation LFS appliance with OpenRC, Wayland, Sway tiling
  compositor, and Greetd.
- `lfs-runit-wayland-hyprland.json`: Dynamic tiling Wayland LFS appliance with Runit supervisor,
  Hyprland, and Greetd.
- `lfs-s6-wayland-labwc.json`: Stacking Wayland LFS appliance with S6/S6-rc supervision, Labwc
  compositor, and Greetd.
- `lfs-systemd-wayland-gnome.json`: Full-featured modern LFS desktop appliance with Systemd,
  Wayland, GNOME suite, and GDM.
- `lfs-systemd-wayland-plasma6.json`: Modern LFS desktop appliance with Systemd, Wayland, KDE Plasma
  6, and SDDM.
- `lfs-dinit-musl-minimal.json`: Ultra-lightweight microVM/container LFS appliance with Musl libc
  and Dinit supervisor.

### General & Cloud Profiles

- `firecracker-microvm-appliance.json`: Minimalist Firecracker microVM image with tailored Linux
  kernel.
- `freebsd-desktop-xfce.json`: FreeBSD workstation profile running XFCE desktop environment.
- `freebsd-server-standard.json`: Hardened FreeBSD standard server configuration.
- `linux-desktop-hyprland.json`: Modern Linux Wayland compositor workstation with Hyprland.
- `linux-desktop-kde-plasma.json`: Full-featured Linux workstation running KDE Plasma 6.
- `linux-desktop-sway-wayland.json`: Tiling Wayland workstation environment with Sway.
- `linux-desktop-xfce-x11.json`: Lightweight X11 desktop workstation with XFCE.
- `linux-minimal-headless-musl.json`: Stripped-down musl-based embedded/headless Linux system.
- `linux-standard-server-glibc.json`: General-purpose production Linux server with glibc.
- `osv-cloud-runtime.json`: OSv unikernel cloud runtime profile.
- `unikraft-nginx-redis.json`: Unikraft unikernel appliance bundling Nginx and Redis.

## Usage

Profiles are compiled using the LibScript OS orchestrator:

```sh
./libscript.sh os-build profiles/linux-standard-server-glibc.json
```
