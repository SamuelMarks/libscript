# LibScript System Profiles

## Overview

Contains declarative JSON blueprint specifications defining complete operating system profiles,
microVM appliances, desktop environments, and server images orchestrated by LibScript.

## Available Profiles

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
