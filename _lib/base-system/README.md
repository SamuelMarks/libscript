# Base System, LibC & Filesystem Utilities (`_lib/base-system/`)

## Overview

**Tier Scope**: `T2`

Foundational OS userland and sysroot libraries (`glibc`, `musl`, `coreutils`, `util-linux`, `pam`,
`shadow`, `sudo`, `doas`, `dbus`, `eudev`, `kmod`, `e2fsprogs`, `btrfs-progs`, `xfsprogs`,
`dosfstools`, `lfs-*`).

Each subdirectory in `_lib/base-system/` is an atomic, self-contained LibScript component governed
by its own `manifest.json` and `vars.schema.json`. Components in `_lib/base-system/` never
cross-source sibling components directly; instead, they source `T0` helpers from `engine/common/`
and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and
`Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh btrfs-progs --help
./libscript.sh install btrfs-progs latest
./_lib/base-system/btrfs-progs/cli.sh test
```

```cmd
.\libscript.cmd btrfs-progs --help
.\libscript.cmd install btrfs-progs latest
.\_lib\base-system\btrfs-progs\cli.cmd test
```

## Musl Sysroot Sub-Recipes (`_lib/base-system/musl/`)

Standalone musl companion libraries and userland applets staged during musl-targeted `T3` builds:
[`argp-standalone`](./musl/argp-standalone/README.md), [`busybox`](./musl/busybox/README.md),
[`eudev-musl`](./musl/eudev-musl/README.md), [`gettext-tiny`](./musl/gettext-tiny/README.md),
[`libucontext`](./musl/libucontext/README.md), [`mdev`](./musl/mdev/README.md),
[`mdevd`](./musl/mdevd/README.md), [`musl`](./musl/musl/README.md),
[`musl-fts`](./musl/musl-fts/README.md), [`musl-obstack`](./musl/musl-obstack/README.md),
[`toybox`](./musl/toybox/README.md).

## Components (21)

<!-- BEGIN_COMPONENTS -->

- [`btrfs-progs`](./btrfs-progs/README.md) (`T2` — `sysroot-package`): Btrfs filesystem creation and
  management tools
- [`coreutils`](./coreutils/README.md) (`T2` — `sysroot-package`): Basic file, shell and text
  manipulation utilities
- [`dbus`](./dbus/README.md) (`T2` — `sysroot-package`): Freedesktop D-Bus inter-process
  communication message bus daemon (dbus-daemon) and CLI tools.
- [`doas`](./doas/README.md) (`T2` — `sysroot-package`): Lightweight OpenBSD privilege escalation
  utility
- [`dosfstools`](./dosfstools/README.md) (`T2` — `sysroot-package`): FAT and VFAT filesystem
  utilities
- [`e2fsprogs`](./e2fsprogs/README.md) (`T2` — `sysroot-package`): Ext2/Ext3/Ext4 filesystem
  management utilities
- [`eudev`](./eudev/README.md) (`T2` — `sysroot-package`): Device node manager daemon and library
- [`glibc`](./glibc/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Core C library and
  dynamic linker
- [`kmod`](./kmod/README.md) (`T2` — `sysroot-package`): Linux kernel module loader and management
  library
- [`lfs-base`](./lfs-base/README.md) (`T2` — `sysroot-package`): Linux From Scratch (LFS) final
  chroot userland and base system synthesis.
- [`lfs-temp-tools`](./lfs-temp-tools/README.md) (`T2` — `sysroot-package`): Linux From Scratch
  (LFS) Chapter 6/7 cross-compiled temporary userland utilities.
- [`locales`](./locales/README.md) (`T2` — `sysroot-package`): POSIX and GNU C Library (glibc)
  system locale definition compiler (localedef / locale-gen) and declarative locale staging.
- [`musl`](./musl/README.md) (`T2` — `sysroot-package`): Clean, efficient and standards-conformant C
  library implementation for Linux
- [`ntp`](./ntp/README.md) (`T2` — `sysroot-package`, `service-daemon`): Reference Network Time
  Protocol (NTP) clock synchronization daemon (ntpd) and query tools.
- [`pam`](./pam/README.md) (`T2` — `sysroot-package`): Pluggable Authentication Modules library
- [`shadow`](./shadow/README.md) (`T2` — `sysroot-package`): User account and password management
  suite
- [`sudo`](./sudo/README.md) (`T2` — `sysroot-package`): Privilege escalation tool for system
  administration
- [`sysctl`](./sysctl/README.md) (`T2` — `sysroot-package`): Declarative kernel runtime parameter
  manager (sysctl and /etc/sysctl.d drop-in configuration).
- [`tzdata`](./tzdata/README.md) (`T2` — `sysroot-package`): IANA Time Zone Database (tzdata)
  compiler and zone dumper utilities (zdump, zic) with declarative /etc/localtime staging.
- [`util-linux`](./util-linux/README.md) (`T2` — `sysroot-package`): Essential system administration
  and disk utilities
- [`xfsprogs`](./xfsprogs/README.md) (`T2` — `sysroot-package`): XFS filesystem administration
  utilities

<!-- END_COMPONENTS -->
