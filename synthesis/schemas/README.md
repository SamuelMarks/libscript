# Tier 3 (`T3`) Synthesis & Execution Plan Schemas (`synthesis/schemas/`)

## Overview

`synthesis/schemas/` defines the JSON Schema (Draft 2020-12) contracts for declarative OS
configurations (`os-config.schema.json`) and target-specific execution plans consumed by
`engine/solver/execute_plan.*` and `synthesis/distro/*`.

## Schemas

- **`os-config.schema.json`**: User-facing OS synthesis profile schema validated by
  `./libscript.sh config os --validate=<file>`.
- **`execution-plan-common.schema.json`**: Shared stage, filesystem, partition, user, and package
  primitives inherited by all OS execution plans.
- **`execution-plan.schema.json`**: Standard Linux, container, and unikernel synthesis execution
  plan.
- **`execution-plan.freebsd.schema.json`**: FreeBSD kernel/world, ZFS pool, and `pkg`/ports
  synthesis plan.
- **`execution-plan.illumos.schema.json`**: illumos/OmniOS ZFS boot environment, SMF, and `pkgsrc`
  plan.
- **`execution-plan.reactos.schema.json`**: ReactOS `i686`/`x86_64` ISO repack and RosBE build plan
  with strict PE bitness invariants.
- **`execution-plan.rtos.schema.json`**: Zephyr RTOS and FreeRTOS board, Kconfig/devicetree, and
  MCUboot firmware signing plan.
- **`execution-plan.live.schema.json`**: Universal `msi-rs` multiboot Live-CD / Live-USB installer
  plan.
