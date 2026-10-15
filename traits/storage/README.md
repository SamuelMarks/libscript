# Storage & Persistent Volumes Trait (`traits/storage/`)

## Overview

`traits/storage/` manages persistent block storage, Copy-on-Write datasets, and network filesystems
by delegating device discovery and formatting to `_lib/storage/disk_discovery.{sh,cmd}` and
`_lib/storage/format_fs.{sh,cmd}`.

## Safety & Dual-Mode Invariants

1. **Non-Destructive Formatting**: `mount.{sh,cmd}` inspects existing partition signatures (`blkid`
   / `fstyp`) and never formats a device that already contains a valid filesystem.
2. **Idempotent `/etc/fstab` & `/etc/vfstab` Reconciliation**: Entries are enclosed inside
   `# BEGIN libscript-trait-storage: <mount>` / `# END libscript-trait-storage: <mount>` markers.
3. **Tier 2 Offline Bake Mode (`LIBSCRIPT_TARGET_SYSROOT != /`)**: Emits `/etc/fstab` or
   `/etc/vfstab` entries into `${LIBSCRIPT_TARGET_SYSROOT}/etc/` without invoking live `mount`
   syscalls.
