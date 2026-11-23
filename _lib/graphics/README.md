# DRM, Mesa OpenGL/Vulkan & Hardware Media Drivers (`_lib/graphics/`)

## Overview

**Tier Scope**: `T2`

Direct Rendering Manager (`libdrm`), Mesa 3D Gallium/Vulkan (`mesa`, `vulkan-loader`), NVIDIA
drivers, and VA-API/VDPAU video acceleration libraries.

Each subdirectory in `_lib/graphics/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/graphics/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh intel-media-driver --help
./libscript.sh install intel-media-driver latest
./_lib/graphics/intel-media-driver/cli.sh test
```

```cmd
.\libscript.cmd intel-media-driver --help
.\libscript.cmd install intel-media-driver latest
.\_lib\graphics\intel-media-driver\cli.cmd test
```

## Components (7)

<!-- BEGIN_COMPONENTS -->

- [`intel-media-driver`](./intel-media-driver/README.md) (`T2` — `sysroot-package`,
  `sysroot-library`): VAAPI hardware accelerated video driver for Intel
- [`libdrm`](./libdrm/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Low-level userspace
  interface to kernel DRM
- [`libva`](./libva/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Video Acceleration API
  library
- [`libvdpau`](./libvdpau/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Video Decode and
  Presentation API for Unix
- [`mesa`](./mesa/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Open-source OpenGL and
  Vulkan driver collection
- [`nvidia`](./nvidia/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Proprietary NVIDIA
  display driver and libraries
- [`vulkan-loader`](./vulkan-loader/README.md) (`T2` — `sysroot-package`, `sysroot-library`):
  Khronos Vulkan ICD loader and headers

<!-- END_COMPONENTS -->
