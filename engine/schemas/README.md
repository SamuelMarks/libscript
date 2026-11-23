# Tier 0 (`T0`) Core JSON Schemas (`engine/schemas/`)

## Overview

`engine/schemas/` defines the `T0` JSON Schema (Draft 2020-12) contracts governing component
manifests, global framework variables, consensus state machines, database inventories, and TFRC/GCS
guardrails.

## Schemas

- **`manifest.schema.json`**: Canonical contract for atomic `T1`/`T2` `_lib/` component
  `manifest.json` files (`tier`, `capabilities`, `provides`, `conflicts`, `dependencies`,
  `variants`, `os_whitelist`, `os_blacklist`, `replaces_version_managers`).
- **`base_vars.schema.json`**: Global framework variables (`LIBSCRIPT_ROOT_DIR`, `LIBSCRIPT_HOME`,
  `LIBSCRIPT_DATA_DIR`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`, `TARGET_OS`, `TARGET_ARCH`, `LIBSCRIPT_STAGE`) rendered into
  `engine/common/README.md`.
- **`consensus-common.schema.json` & `consensus-state.schema.json`**: Quorum lease epochs, fencing
  policies, and atomic `.topology_state.json` state-machine checkpoints for `engine/consensus/`.
- **`database_inventory.schema.json`**: Logical database tenant, user, and credential inventory
  contract consumed by `engine/hooks/databases/`.
- **`gcs-ml-storage.schema.json`**: 4-role regional Google Cloud Storage bucket layout (`datasets`,
  `checkpoints`, `logs`, `artifacts`) enforcing zero cross-region egress for TPU/GPU workloads.
- **`tfrc-policy.schema.json`**: Strict `$0.00` Google TPU Research Cloud (TFRC) quota, zone,
  accelerator SKU, and billing guardrail contract enforced by `engine/common/tfrc_guard.{sh,cmd}`.
