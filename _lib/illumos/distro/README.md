# illumos Modular Distribution Substrate (`_lib/illumos/distro/`)

## Overview

The `_lib/illumos/distro/` directory houses modular assembly scripts for synthesizing tailored,
production-ready illumos distributions. It implements declarative, profile-driven component
selection across:

- **Base System Bootstrap**: Sysroot directory staging, userland proto-area setup, and release
  metadata validation (`base.sh`, `base.cmd`).
- **ZFS Dataset Hierarchy & Storage Management**: Canonical ZFS root pool (`rpool`) architecture,
  dataset layouts, `/etc/vfstab` generation, and boot environment configurations (`zfs.sh`,
  `zfs.cmd`).
- **Core System Configuration**: Nodename, hosts, login defaults, PAM, `/etc/nsswitch.conf`, DNS
  resolver, and serial console redirection (`config.sh`, `config.cmd`).
- **Package Management**: Official IPS (`pkg(1)`) repository mirrors, Joyent `pkgin`/`pkgsrc`
  bootstrap, or Tribblix `zap` catalogs (`pkg.sh`, `pkg.cmd`).
- **User Accounts & RBAC**: User creation, groups (`staff`, `sysadmin`), Solaris RBAC execution
  profiles (`Primary Administrator`), passwordless `sudoers.d`, `doas.conf`, and SSH authorized keys
  (`users.sh`, `users.cmd`).
- **Pluggable Init Systems**: Service supervision supporting native illumos SMF (`svc.startd`),
  `runit`, `s6`, `dinit`, and traditional SysV `/etc/inittab` (`init.sh`, `init.cmd`).
- **Display Protocols & Drivers**: Headless serial console mode, X11 Xorg server with
  VESA/modesetting/virtio drivers, or experimental Wayland (`display.sh`, `display.cmd`).
- **Desktop Environments**: MATE Desktop, XFCE4, Common Desktop Environment (CDE), and minimal
  window managers (`openbox`, `fluxbox`, `i3`, `dwm`) (`desktop.sh`, `desktop.cmd`).
- **Display Managers**: LightDM, SLiM, XDM, CDE dtlogin, and console `ttymon` login (`dm.sh`,
  `dm.cmd`).
- **Audio Subsystems**: Native Solaris Boomer in-kernel audio (`/dev/audio`), Open Sound System
  (OSS), PulseAudio, or headless none (`audio.sh`, `audio.cmd`).
- **Assembly Orchestrator**: JSON profile reader and pipeline coordinator (`assemble.sh`,
  `assemble.cmd`).

## Usage

To assemble a distribution sysroot from an illumos profile:

```sh
./_lib/illumos/distro/assemble.sh profiles/illumos/minimal-server.json build/illumos-sysroot
```

On Windows Command Prompt:

```cmd
.\_lib\illumos\distro\assemble.cmd profiles\illumos\minimal-server.json build\illumos-sysroot
```

## Profiles

Preset profiles are located in `profiles/illumos/`:

- `minimal-server.json`: Headless server with native SMF init, ZFS root pool, and minimal footprint.
- `zfs-cloud.json`: Cloud and Vagrant appliance with SMF, ZFS dataset hierarchies, and vagrant
  bootstrap credentials.
- `desktop-mate-x11.json`: Full illumos workstation with SMF, X11 Xorg server, MATE desktop suite,
  LightDM, and Boomer audio.
- `desktop-xfce-x11.json`: Lightweight workstation with SMF, X11 Xorg server, XFCE4 desktop suite,
  Slim login manager, and Boomer audio.
- `cde-retro-x11.json`: Classic Solaris Common Desktop Environment (CDE) with Xorg, dtlogin/xdm, and
  traditional appearance.
- `hardened-runit.json`: Minimal hardened micro-appliance running runit process supervision with
  zero GUI footprint.
- `pkgsrc-developer.json`: Developer-centric workstation profile with Joyent pkgin/pkgsrc bootstrap,
  build toolchains, and ZFS workspaces.

## Invariants & Design Guarantees

1. **Strict POSIX /bin/sh**: All `.sh` scripts adhere to POSIX standards with zero bashisms and
   utilize the canonical `THIS_FILE=` preamble and re-entrant `STACK` recursion guards.
2. **Windows Parity**: Every `.sh` script has an exact `.cmd` companion implementing identical
   flags, default paths, and delayed expansion.
3. **Idempotency**: All operations are guarded by `.libscript_stamps/*.stamp` files and defensive
   checks ensuring repeated runs produce zero drift and exit code `0`.
4. **100% Documentation**: Every script contains structured `## Overview` and `## Usage` headers
   within the first 30 lines.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
