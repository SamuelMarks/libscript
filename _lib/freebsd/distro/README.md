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

| Variable                        | Description                                                                                                                             | Default            | Aliases/Examples             |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                             | `none`             | LIBSCRIPT_TARGET_ROOTFS      |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                     | `none`             |                              |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                               | `none`             |                              |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                | `none`             |                              |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                               | `none`             |                              |
| `LIBSCRIPT_STAGE`               | Active multi-stage Tier 2 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                       | `none`             |                              |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.     | `0`                |                              |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.      | `0`                |                              |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent. | `0`                |                              |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.               | `none`             |                              |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                      | `none`             |                              |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                    | `9`                |                              |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                       | `none`             |                              |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                     | `none`             |                              |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                               | `none`             |                              |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                            | `none`             |                              |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                  | `none`             |                              |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                           | `none`             |                              |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                  | `none`             |                              |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                       | `none`             |                              |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                    | `none`             |                              |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                  | `none`             |                              |
| `FREEBSD_DISTRO_VERSION`        | Target FreeBSD release version to synthesize.                                                                                           | `14.1-RELEASE`     |                              |
| `FREEBSD_DISTRO_INSTALL_METHOD` | How to run FreeBSD distro synthesis ('libscript_native' or 'system').                                                                   | `libscript_native` |                              |
| `FREEBSD_DISTRO_BUILDWORLD`     | Flag (0 or 1) instructing FreeBSD synthesis to execute buildworld and buildkernel from FREEBSD_SRC_DIR.                                 | `0`                | LIBSCRIPT_FREEBSD_BUILDWORLD |
| `FREEBSD_DISTRO_FETCH_BASE`     | Flag (0 or 1) instructing FreeBSD synthesis to download and extract official FreeBSD base.txz and kernel.txz archives.                  | `0`                | LIBSCRIPT_FETCH_FREEBSD_BASE |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
