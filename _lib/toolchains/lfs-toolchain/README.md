# LFS Cross-Toolchain

## Purpose & Overview

Provides the Stage 1 and Stage 2 cross-compilation toolchain bootstrap for synthesizing Linux From
Scratch operating system appliances (Binutils, GCC Stage 1 & 2, kernel API headers, Glibc / Musl).

## Usage

```sh
# Bootstrap cross-toolchain sysroot
./_lib/toolchains/lfs-toolchain/setup.sh install --libc=glibc --arch=x86_64

# Check toolchain status
./_lib/toolchains/lfs-toolchain/setup.sh status
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
