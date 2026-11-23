# Tier 0 (`T0`) Target Triplet & Runtime Discovery (`engine/target/`)

## Overview

`engine/target/` provides `T0` target architecture normalization and host runtime probing used by
cross-toolchains (`_lib/toolchains/`), source builders (`engine/common/source_builder.*`), and OS
synthesizers (`synthesis/`).

## Modules

- **`triplets.{sh,cmd}`**: Normalizes target OS, CPU ISA (`x86_64`, `aarch64`, `riscv64`, `i686`,
  `armv7l`, `xtensa`), ABI, and C standard library (`glibc`, `musl`, `bsd-libc`, `msvcrt`, `ucrt`,
  `newlib`, `picolibc`) into canonical GNU/LLVM target triplets (e.g.,
  `x86_64-libscript-linux-musl`, `i686-w64-mingw32`, `aarch64-unknown-freebsd15.1`).
- **`discover_runtimes.{sh,cmd}`**: Probes installed language runtimes, compilers, hypervisors, and
  versioned toolchains under `${LIBSCRIPT_HOME}` and host `PATH`, emitting structured inventory data
  without mutating host state.

## Usage

```sh
./engine/target/triplets.sh --arch x86_64 --os linux --libc musl
./engine/target/discover_runtimes.sh
```

```cmd
.\engine\target\triplets.cmd --arch i686 --os windows --libc ucrt
.\engine\target\discover_runtimes.cmd
```
