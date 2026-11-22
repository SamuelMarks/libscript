# Tier 0 (`T0`): Core Engine, Solver & Consensus Substrate (`engine/`)

## Overview

`engine/` houses the zero-domain `T0` runtime substrate for LibScript. Nothing in `engine/` is an
installable user component; instead, every higher tier (`T1`–`T5`) and orthogonal plane
(`Plane A: traits/`, `Plane B: experiments/`) builds on these primitives strictly downward:

- `engine/common/`: Cross-platform POSIX `/bin/sh` and Windows Batch (`.cmd`) standard libraries
  (`pkg_mgr`, `source_builder`, `component_core`, `setup_base`, `service`, `versioning`, `context`,
  `env_base`, `priv`, `remote_sync`, `python_env`, `win32/`, `dos32/`).
- `engine/schemas/`: Foundational JSON Schemas (`manifest.schema.json`, `base_vars.schema.json`,
  `consensus-common.schema.json`, `consensus-state.schema.json`).
- `engine/solver/`: Pure `jq` Tarjan SCC dependency resolver (`resolve_stack`) and idempotent
  execution plan runner (`execute_plan`).
- `engine/hooks/`: Dual-layer (`physical` vs. `logical`) component lifecycle hook dispatcher
  (`run_hooks`).
- `engine/target/`: Cross-compilation target-triple normalizer (`triplets`) and runtime discovery
  (`discover_runtimes`).
- `engine/consensus/`: Distributed lease-locking (`lock`) and split-brain fencing (`fence`) state
  machine primitives.
