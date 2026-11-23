# Shared Domain Variable Schemas (`schemas/`)

## Overview

`schemas/` contains modular JSON Schema variable packs (`schemas/vars/*.schema.json`) referenced by
component and subsystem `vars.schema.json` manifests via `"x-libscript-var-packs"`. Splitting
domain-specific variables out of `engine/schemas/base_vars.schema.json` keeps `T0` free of cloud,
TPU, RTOS, or experiment-specific variable leakage while allowing `devtools/docs-gen/` to compose
complete variable tables automatically.

## Subdirectories

- [`schemas/vars/`](./vars/README.md): Domain variable schema packs (`cloud_tags`, `experiment`,
  `image_synth`, `rtos`, `source_toolchain`, `tfrc`, `tpu`) and `baseline-disposition.json`.
