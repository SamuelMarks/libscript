# Accelerator & WebAssembly Execution Runtimes (`_lib/runtimes/`)

## Overview

**Tier Scope**: `T1 / T2`

Hardware ML accelerator runtimes (`libtpu`) and lightweight WebAssembly Micro Runtimes (`wamr`) for
cloud, edge, and RTOS targets.

Each subdirectory in `_lib/runtimes/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/runtimes/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh libtpu --help
./libscript.sh install libtpu latest
./_lib/runtimes/libtpu/cli.sh test
```

```cmd
.\libscript.cmd libtpu --help
.\libscript.cmd install libtpu latest
.\_lib\runtimes\libtpu\cli.cmd test
```

## Components (2)

<!-- BEGIN_COMPONENTS -->

- [`libtpu`](./libtpu/README.md) (`T1` — `userland-package`): Isolated version manager and SHA-256
  verified artifact cache for upstream PyPI libtpu wheels (libtpu.so and sdk.so).
- [`wamr`](./wamr/README.md) (`T1` — `userland-package`): Bytecode Alliance WebAssembly Micro
  Runtime (iwasm and embeddable libiwasm) for Linux, BSD, Zephyr RTOS, and FreeRTOS.

<!-- END_COMPONENTS -->
