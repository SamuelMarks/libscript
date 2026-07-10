# TPU Research Cloud (TFRC) Expansion Plan

This document outlines the exhaustive task list required to extend `libscript`'s GCP Cloud TPU
provisioning interface to natively and robustly support TPU Research Cloud (TFRC) constraints.

TFRC grants come with strict limitations on regions, accelerator types, quantities, and scheduling
types (preemptible vs. on-demand). Because TFRC utilizes spare capacity, requests are highly prone
to availability errors, requiring a more resilient provisioning pipeline.

## 1. Schema & Validation (`vars.schema.json`)

Currently, `tpu-vm` variables are loosely managed or missing from the schema. We need rigorous
validation to prevent quota errors at the CLI boundary.

- [x] Add `TPU_SCHEDULING_TYPE` to `_lib/cloud-providers/gcp/tpu-vm/vars.schema.json`.
  - [ ] Type: string.
  - [ ] Enum: `["on-demand", "spot", "preemptible"]`.
  - [ ] Default: `"on-demand"`.
- [x] Add `TPU_ACCELERATOR_TYPE` to the schema.
  - [ ] Type: string.
  - [ ] Document valid TFRC strings (e.g., `v2-8`, `v3-8`, `v4-8`, `v3-32`).
- [x] Add `TPU_ZONE` to the schema.
  - [ ] Type: string.
  - [ ] Ensure description notes the importance of matching the specific TFRC granted zone.
- [x] Add `TPU_VERSION` to the schema.
  - [ ] Type: string.
  - [ ] Default: `"tpu-ubuntu2204-base"`.
- [x] Add `TPU_COUNT` to the schema for multi-node provisioning.
  - [ ] Type: integer.
  - [ ] Default: `1`.
- [x] Add `TPU_USE_QUEUED_RESOURCE` to the schema.
  - [ ] Type: boolean.
  - [ ] Default: `false`.
- [x] Implement a pre-flight validation check in `setup_generic.sh` / `setup.sh` that maps
      `TPU_ACCELERATOR_TYPE` to known compatible OS versions, warning users if they choose an
      incompatible pair.

## 2. CLI Interface & Provisioning Logic (`cli.sh`)

The core script (`cli.sh`) must translate these new variables into correct `gcloud` flags.

### 2.1 Scheduling Type (Spot / Preemptible)

- [x] Update `cli.sh` to read `TPU_SCHEDULING_TYPE`.
- [x] If `TPU_SCHEDULING_TYPE="spot"`, append `--spot` to the `gcloud compute tpus tpu-vm create`
      command.
- [x] If `TPU_SCHEDULING_TYPE="preemptible"`, append `--preemptible` to the command.
- [x] Add robust error handling to immediately surface messages indicating preemptible quota
      exhaustion.

### 2.2 Pod & Multi-Worker Support

TFRC occasionally grants multi-node Pod slices (e.g., `v3-32`).

- [x] Modify `cli.sh ssh` to parse a `--all-workers` flag.
- [x] When `--all-workers` is passed, inject `--worker=all` into the
      `gcloud compute tpus tpu-vm ssh` command to allow distributed command execution.
- [x] Implement a helper command `tpu-vm scp` to facilitate copying model weights or datasets to all
      workers in a Pod slice simultaneously using `gcloud compute tpus tpu-vm scp --worker=all`.

### 2.3 Multi-Instance Bulk Provisioning

TFRC often grants multiple independent devices (e.g., 5 `v2-8` instances).

- [x] Update `tpu-vm create` to loop over `TPU_COUNT`.
- [x] Format instance names predictably (e.g., if user requests `<name>`, provision `<name>-1`,
      `<name>-2`, etc., unless count is 1).
- [x] Update `tpu-vm delete`, `start`, and `stop` commands to accept a `--all` flag or respect
      `TPU_COUNT` to batch process operations on identically prefixed resources.

### 2.4 Disk & Storage Handling

- [x] Allow passing an array or sequence of disk attachments for multi-instance provisioning (e.g.,
      formatting `<name>-1-data`, `<name>-2-data`).
- [x] Ensure that when deleting multiple instances, their respective data disks are accurately
      tracked and deleted.

## 3. Resiliency & Availability: Queued Resources API

Because TFRC relies on spare capacity, on-demand/synchronous creations frequently fail with "out of
resources" (Code: 429 or 503). Integrating the Queued Resources API is critical for a smooth user
experience.

- [x] Implement a new branch in the `create` logic: if `TPU_USE_QUEUED_RESOURCE="true"`.
- [x] Map the request to use `gcloud alpha compute tpus queued-resources create <name>`.
- [x] Translate standard `tpu-vm create` flags to the Queued Resource equivalent format (e.g.,
      specifying `--node-id`, `--zone`, `--accelerator-type`).
- [x] Implement a `libscript gcp/tpu-vm status <name>` command to poll and report the state of a
      Queued Resource (e.g., `ACCEPTED`, `PROVISIONING`, `ACTIVE`, `FAILED`).
- [x] Update `tpu-vm delete` to support cleaning up both the TPU VM and the Queued Resource request
      itself (to prevent accidental provisioning after the user gives up).

## 4. Documentation & Examples

- [x] Update `_lib/cloud-providers/gcp/tpu-vm/README.md`.
- [x] Provide an explicit example configuration block for a standard TFRC `v2-8` preemptible setup.
- [x] Provide an explicit example for a TFRC Pod slice setup (`v3-32`).
- [x] Document the "Out of capacity" error mitigation strategy and how to use
      `TPU_USE_QUEUED_RESOURCE`.
- [x] Document the multi-worker SSH workflow (`--all-workers`) for Jax/PyTorch distributed training
      across a pod.

## 5. End-to-End Testing (Optional/Advanced)

- [x] Update `test.sh` for the `tpu-vm` component to simulate variable injection for a
      spot/preemptible config.
- [x] Use `--dry-run` or similar mocking mechanisms to verify the correct `gcloud` string is
      generated without actually consuming GCP quota.

## 6. Coding Standards & Compliance

All implementations must rigorously adhere to the global `libscript` quality standards.

- [x] **POSIX Compliance:** Ensure all shell scripts (`cli.sh`, `setup.sh`, etc.) use `/bin/sh`
      strictly.
  - [x] Avoid bashisms (e.g., `[[ ]]`, arrays).
  - [x] Retain and correctly use the standard `THIS_FILE=` preamble dance for resolving dependencies
        and paths.
- [x] **Windows Parity:** For every `.sh` script updated, implement the exact equivalent logic in
      the corresponding `.cmd` Windows batch script (e.g., `cli.cmd`).
- [x] **Documentation Coverage:** Ensure 100% documentation coverage. Every new command, flag, and
      configuration variable must be documented in `README.md` and `vars.schema.json`.
