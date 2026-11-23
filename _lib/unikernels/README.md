# Single-Address-Space Unikernel Toolchains (`_lib/unikernels/`)

## Overview

**Tier Scope**: `T2`

Unikernel build systems and hypervisor tenders (`osv`, `nanos`, `unikraft`, `mirage`, `rumprun`,
`solo5`) consumed by `T3` `synthesis/formats/unikernel_img.*`.

Each subdirectory in `_lib/unikernels/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/unikernels/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh mirage --help
./libscript.sh install mirage latest
./_lib/unikernels/mirage/cli.sh test
```

```cmd
.\libscript.cmd mirage --help
.\libscript.cmd install mirage latest
.\_lib\unikernels\mirage\cli.cmd test
```

## Components (6)

<!-- BEGIN_COMPONENTS -->

- [`mirage`](./mirage/README.md) (`T2` — `sysroot-package`): OCaml library operating system and
  Solo5 (hvt/spt) unikernel synthesizer.
- [`nanos`](./nanos/README.md) (`T2` — `sysroot-package`): NanoVMs Ops CLI and Nanos unikernel image
  packager running unmodified ELF binaries on KVM, QEMU, Xen, and cloud hypervisors.
- [`osv`](./osv/README.md) (`T2` — `sysroot-package`): OSv cloud unikernel runtime and Capstan image
  builder with ZFS, ROFS, and unmodified Linux PIE shared-object support.
- [`rumprun`](./rumprun/README.md) (`T2` — `sysroot-package`): NetBSD rump kernel unikernel
  cross-toolchain and rumpbake image baker targeting KVM/VirtIO (hw_virtio) and Xen.
- [`solo5`](./solo5/README.md) (`T2` — `sysroot-package`): Sandboxed execution environment for
  unikernels using KVM/bhyve
- [`unikraft`](./unikraft/README.md) (`T2` — `sysroot-package`): Modular POSIX-compatible unikernel
  SDK and KraftKit image builder targeting KVM, Firecracker, and Xen.

<!-- END_COMPONENTS -->
