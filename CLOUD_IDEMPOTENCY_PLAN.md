# Cloud Operations Idempotency Plan

**Goal:** Ensure that cloud resource operations (create, delete, etc.) across AWS, Azure, and GCP
are idempotent (guarded).

- **Create:** Do not attempt to provision a resource if it already exists; output that it exists and
  succeed.
- **Delete:** Do not fail if attempting to delete a resource that has already been removed or does
  not exist; output that it is already gone and succeed.

## 1. Scope of Changes

The following providers and components contain cloud provisioning logic:

- **AWS**: `_lib/cloud-providers/aws/cli.sh` (and `.ps1`, `.cmd` equivalents)
- **Azure**: `_lib/cloud-providers/azure/setup_generic.sh`, `azure/setup.ps1`
- **GCP**:
  - `_lib/cloud-providers/gcp/setup_generic.sh`, `gcp/setup.ps1`
  - Sub-components: `gpu-vm`, `tpu-vm`, `filestore` (some of which already have partial guards in
    their respective `cli.sh`/`cli.cmd`)

## 2. Provider Implementation Details

### AWS (`_lib/cloud-providers/aws/cli.sh`)

- [x] **Action Items:**
  - Locate `delete` actions for `node`, `network`, `firewall`, etc.
  - Change logic to `exit 0` if the resource is already deleted or not found.
  - Ensure idempotency for `node`, `firewall`, `storage`, and `dns`.

### Azure (`_lib/cloud-providers/azure/setup_generic.sh` & `setup.ps1`)

- [x] **Action Items:**
  - **Create Operations:** Wrap creations in a check using `az <resource> show` or
    `az <resource> list`.
  - **Delete Operations:** Wrap deletions or ignore errors if missing.
  - Apply this to: Virtual Machines, VNets, NSGs, DNS Zones, and DNS Records.

### GCP (`_lib/cloud-providers/gcp/setup_generic.sh` & `setup.ps1` & Sub-components)

- [x] **Current State:** Standard GCP commands invoke `gcloud compute instances create`
      unconditionally. Sub-components like `gpu-vm` and `tpu-vm` have some partial `describe`
      checks.
- [x] **Action Items:**
  - **Create Operations:** Prefix creations with `gcloud compute <type> describe`.
  - **Delete Operations:** Prefix deletions with existence checks.
  - Apply this uniformly across: Instances, Networks, Firewalls, DNS Managed Zones, and DNS Record
    Sets.
  - Audit `tpu-vm`, `gpu-vm`, and `filestore` to ensure their existing guards strictly return
    `exit 0` on redundant operations.

## 3. Testing and Validation

- [x] 1. **Unit/Integration Tests:** Run existing tests in `aws/test.sh`, `azure/test.sh`, and
      `gcp/test.sh` to ensure no syntax errors are introduced.
- [x] 2. **Double-Create Test:** Manually run a create operation twice for each provider to confirm
      the second run exits `0` without side effects.
- [x] 3. **Double-Delete Test:** Manually run a delete operation on a non-existent (or just deleted)
      resource to confirm it exits `0`.
