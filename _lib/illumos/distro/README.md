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

| Variable                        | Description                                                                                                                                  | Default            | Aliases/Examples             |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                  | `none`             | LIBSCRIPT_TARGET_ROOTFS      |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                          | `none`             |                              |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                    | `none`             |                              |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                     | `none`             |                              |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                    | `none`             |                              |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                            | `none`             |                              |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.          | `0`                |                              |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.           | `0`                |                              |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.      | `0`                |                              |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                    | `none`             |                              |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                           | `none`             |                              |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                         | `9`                |                              |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                            | `none`             |                              |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                          | `none`             |                              |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                    | `none`             |                              |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                 | `none`             |                              |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                       | `none`             |                              |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                | `none`             |                              |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                       | `none`             |                              |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                            | `none`             |                              |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                         | `none`             |                              |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                       | `none`             |                              |
| `ILLUMOS_DISTRO_VERSION`        | Target illumos/OmniOS release version to synthesize.                                                                                         | `r151050`          |                              |
| `ILLUMOS_DISTRO_INSTALL_METHOD` | How to run illumos distro synthesis ('libscript_native' or 'system').                                                                        | `libscript_native` |                              |
| `ILLUMOS_DISTRO_FETCH_BASE`     | Flag (0 or 1) instructing _lib/illumos/distro/base.sh to fetch and extract upstream OmniOS, OpenIndiana, Tribblix, or SmartOS base archives. | `0`                | LIBSCRIPT_FETCH_ILLUMOS_BASE |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
