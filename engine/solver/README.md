# Tier 0 (`T0`) Constraint Solver & Execution Plan Engine (`engine/solver/`)

## Overview

`engine/solver/` implements LibScript's deterministic dependency graph resolver and staged execution
plan runner. It compiles high-level stack specifications (`libscript.json`) and operating system
profiles (`synthesis/profiles/**/*.json`) into topologically ordered execution plans conforming to
`synthesis/schemas/execution-plan.schema.json`.

## Modules

- **`resolve_stack.jq` & `resolve_stack.{sh,cmd,ps1}`**:
  - Crawls `_lib/*/*/manifest.json` catalogs, evaluates `host_tools`, `build_deps`, and
    `runtime_deps`, propagates Gentoo-style `variants` (`wayland`, `vulkan`, `lto`, `musl`),
    validates target architecture/PE bitness and RTOS `fork()` constraints, and breaks circular
    bootstrap dependencies (such as `freetype <-> harfbuzz`) into multi-pass stages via **Tarjan's
    Strongly Connected Components (SCC)** algorithm.
- **`execute_plan.{sh,cmd,ps1}`**:
  - Executes resolved `execution-plan*.json` stages deterministically with `.stamp.*` idempotency
    checkpointing, offline cache enforcement (`LIBSCRIPT_OFFLINE`), and sysroot isolation
    (`LIBSCRIPT_TARGET_SYSROOT`).

## Usage

```sh
# Resolve an OS profile into a deterministic multi-stage execution plan
./engine/solver/resolve_stack.sh --profile synthesis/profiles/linux/linux-minimal-headless-musl.json --output build/plan.json

# Execute the resolved plan
./engine/solver/execute_plan.sh build/plan.json
```

```cmd
.\engine\solver\resolve_stack.cmd --profile synthesis\profiles\reactos\minimal-headless-i686.json --output build\plan.json
.\engine\solver\execute_plan.cmd build\plan.json
```
