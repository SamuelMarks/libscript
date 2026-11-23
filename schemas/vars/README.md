# Modular Variable Schema Packs (`schemas/vars/`)

## Overview

`schemas/vars/` houses composable JSON Schema (Draft 2020-12) variable packs attached to components,
synthesizers, providers, and experiments via the `"x-libscript-var-packs"` array in each module's
`vars.schema.json`. During documentation generation (`devtools/docs-gen/generate_markdown_docs.sh`)
and schema auditing (`devtools/audit/audit_schema_vars.sh`), only the variable packs declared by a
component are merged into its configuration contract.

## Schema Packs

- **`cloud_tags.schema.json`**: Multicloud resource tagging, project, owner, and lifecycle TTL
  variables (`T4` `infrastructure/`).
- **`experiment.schema.json`**: Empirical benchmark suite variables (`Plane B` `experiments/`).
- **`image_synth.schema.json`**: Sysroot, disk layout, filesystem, and bootloader synthesis
  variables (`T3` `synthesis/`).
- **`rtos.schema.json`**: Target board, SoC, Zephyr/FreeRTOS SDK, and MCUboot signing variables
  (`_lib/kernel/{zephyr,freertos}` and `synthesis/formats/firmware_bin.*`).
- **`source_toolchain.schema.json`**: Source compilation toolchain selection (`CC`, `CXX`, `CFLAGS`,
  `LDFLAGS`, `--toolchain`, `--custom-cc`) for `engine/common/source_builder.*`.
- **`tfrc.schema.json`**: Zero-cost TPU Research Cloud (`$0.00` billing guardrail) policy variables.
- **`tpu.schema.json`**: Cloud TPU accelerator topology, slice count, worker lockstep, and XLA
  flags.
- **`baseline-disposition.json`**: Disposition ledger mapping every former monolithic base variable
  to either `engine/schemas/base_vars.schema.json` or its scoped `schemas/vars/*.schema.json` pack.
