# Tier 3 (`T3`) Virtual Filesystem & Sysroot Sandbox (`synthesis/vfs/`)

## Overview

`synthesis/vfs/` manages isolated target root filesystems (`LIBSCRIPT_TARGET_SYSROOT`), FHS
directory hierarchies, pseudo-filesystem mounts (`/proc`, `/sys`, `/dev`, `/dev/pts`, `/run`), and
hermetic chroot/namespace/jail command execution during `T3` image and package synthesis.

On Windows (`Win32`), kernel-bound scripts implement the **Option A Hard-Fail Boundary Proforma**
(exiting with code `86` and directing operators to `engine/common/vm_builder.cmd` or
`libscript.cmd package-as docker`).

## Modules

- **`create_fhs_layout.{sh,cmd}` & `rootfs.{sh,cmd}`**: Creates FHS 3.0 directory layouts (merged or
  split `/usr`), base device nodes, `/etc/passwd`, `/etc/group`, and permissions inside the sysroot.
- **`lfs-mount-vfs.{sh,cmd}` & `lfs-chroot.{sh,cmd}`**: Specialized Linux From Scratch (`LFS`)
  virtual kernel filesystem binder and clean-environment chroot dispatcher.
- **`provision_isolated_runtime.{sh,cmd}`**: Stages isolated language/toolchain runtimes into target
  sysroots without leaking host environment variables.
- [`sysroot/`](./sysroot/README.md): Idempotent VFS mount (`mount_target_vfs.*`) and trap-safe
  unmount (`umount_target_vfs.*`) lifecycle manager.
- [`runner/`](./runner/README.md): Isolated sysroot command execution wrapper (`runner.*`).
