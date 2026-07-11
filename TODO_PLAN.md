# Tag Guardrails Implementation Plan

This document outlines the exhaustive steps required to implement tag-based guardrails for resource
modification and deletion across all cloud provider scripts.

## Phase 1: Core Verification Utilities

Implement the standardized verification function in the core tagging files to prevent logic
duplication.

- [x] Update `_lib/cloud/core/tags.sh`
  - [x] Implement `libscript_verify_managed()` function.
  - [x] Add AWS lookup logic (`node`, `network`, `firewall`, `storage`, `dns`, `volume`, `cdn`,
        `cert`).
  - [x] Add GCP lookup logic (`node`, `network`, `firewall`, `storage`, `dns`, `volume`, `cdn`,
        `cert`, `gpu-vm`, `tpu-vm`, `filestore`).
  - [x] Add Azure lookup logic (`node`, `network`, `firewall`, `storage`, `dns`, `volume`, `cdn`,
        `cert`).
  - [x] Implement the `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1` override check.
  - [x] Add 100% doc coverage (comments).
- [x] Update `_lib/cloud/core/tags.cmd`
  - [x] Implement `:libscript_verify_managed` label.
  - [x] Add AWS lookup logic.
  - [x] Add GCP lookup logic.
  - [x] Add Azure lookup logic.
  - [x] Implement the `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1` override check.
  - [x] Add 100% doc coverage (comments).
- [x] (If applicable) Update/Create `_lib/cloud/core/tags.ps1`
  - [x] Implement `Libscript-VerifyManaged` function (or equivalent).
  - [x] Add AWS/GCP/Azure lookup logic.
  - [x] Implement the override check.
  - [x] Add 100% doc coverage.

## Phase 2: Inject Guards into Cloud Providers (`_lib/cloud-providers/*`)

Inject the verification call immediately before destruction or mutation logic.

### AWS (`_lib/cloud-providers/aws/`)

- [x] `cli.sh`
  - [x] Guard `node update`
  - [x] Guard `node delete`
  - [x] Guard `network update`
  - [x] Guard `network delete`
  - [x] Guard `firewall update`
  - [x] Guard `firewall delete`
  - [x] Guard `storage delete`
  - [x] Guard `dns zone delete`
  - [x] Guard `dns record update`
  - [x] Guard `dns record delete`
- [x] `cli.cmd` / `setup_generic.cmd` (Verify where logic resides)
  - [x] Add guards to corresponding `update`/`delete` actions.
- [x] `cli.ps1` / `setup.ps1` (Verify where logic resides)
  - [x] Add guards to corresponding `update`/`delete` actions.

### Azure (`_lib/cloud-providers/azure/`)

- [x] `setup_generic.sh`
  - [x] Guard `node update`
  - [x] Guard `node delete`
  - [x] Guard `network update`
  - [x] Guard `network delete`
  - [x] Guard `firewall update`
  - [x] Guard `firewall delete`
  - [x] Guard `dns zone delete`
  - [x] Guard `dns record update`
  - [x] Guard `dns record delete`
- [x] `setup_generic.cmd`
  - [x] Add guards to corresponding `update`/`delete` actions.
- [x] `setup.ps1`
  - [x] Guard `node update`
  - [x] Guard `node delete`
  - [x] Guard `network update`
  - [x] Guard `network delete`
  - [x] Guard `firewall update`
  - [x] Guard `firewall delete`
  - [x] Guard `dns zone delete`
  - [x] Guard `dns record update`
  - [x] Guard `dns record delete`

### GCP (`_lib/cloud-providers/gcp/`)

- [x] `setup_generic.sh`
  - [x] Guard `node update`
  - [x] Guard `node delete`
  - [x] Guard `network update`
  - [x] Guard `network delete`
  - [x] Guard `firewall update`
  - [x] Guard `firewall delete`
  - [x] Guard `dns zone delete`
  - [x] Guard `dns record update`
  - [x] Guard `dns record delete`
- [x] `setup_generic.cmd`
  - [x] Add guards to corresponding `update`/`delete` actions.
- [x] `setup.ps1`
  - [x] Guard `node update`
  - [x] Guard `node delete`
  - [x] Guard `network update`
  - [x] Guard `network delete`
  - [x] Guard `firewall update`
  - [x] Guard `firewall delete`
  - [x] Guard `dns zone delete`
  - [x] Guard `dns record update`
  - [x] Guard `dns record delete`

### GCP Specialized Resources

- [x] `gcp/gpu-vm/cli.sh`
  - [x] Guard `delete` (VM)
  - [x] Guard `delete` (data disk)
- [x] `gcp/gpu-vm/cli.cmd`
  - [x] Guard `delete` (VM)
  - [x] Guard `delete` (data disk)
- [x] `gcp/tpu-vm/cli.sh`
  - [x] Guard `delete` (TPU VM)
  - [x] Guard `delete` (Queued Resource)
  - [x] Guard `delete` (data disk)
- [x] `gcp/tpu-vm/cli.cmd`
  - [x] Guard `delete` (TPU VM)
  - [x] Guard `delete` (Queued Resource)
  - [x] Guard `delete` (data disk)
- [x] `gcp/filestore/cli.sh`
  - [x] Guard `delete` (filestore instance)
- [x] `gcp/filestore/cli.cmd`
  - [x] Guard `delete` (filestore instance)
- [x] `gcp/filestore/cli.ps1`
  - [x] Guard `delete` (filestore instance)

## Phase 3: Inject Guards into Higher-Level Abstractions (`_lib/cloud/*`)

Guard the unified cloud wrapper functions that perform direct deletion actions.

### Storage

- [x] `_lib/cloud/storage/api.sh`: Guard `libscript_storage_delete`
- [x] `_lib/cloud/storage/api.cmd`: Guard `:delete` action

### Volume

- [x] `_lib/cloud/volume/api.sh`: Guard `libscript_volume_delete`
- [x] `_lib/cloud/volume/api.cmd`: Guard `:delete` action

### CDN

- [x] `_lib/cloud/cdn/api.sh`: Guard `libscript_cdn_delete`
- [x] `_lib/cloud/cdn/api.cmd`: Guard `:delete` action

### Cert

- [x] `_lib/cloud/cert/api.sh`: Guard `libscript_cert_delete`
- [x] `_lib/cloud/cert/api.cmd`: Guard `:delete` action

## Phase 4: Validation & Testing

Ensure the guardrails function correctly and tests pass.

- [x] Update `test.sh` / `test.cmd` (or equivalent test scripts) in `_lib/cloud-providers/aws/`
  - [x] Verify standard delete fails.
  - [x] Verify `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1` passes/warns.
- [x] Update `test.sh` / `test.cmd` in `_lib/cloud-providers/azure/`
  - [x] Verify standard delete fails.
  - [x] Verify `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1` passes/warns.
- [x] Update `test.sh` / `test.cmd` in `_lib/cloud-providers/gcp/`
  - [x] Verify standard delete fails.
  - [x] Verify `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1` passes/warns.
