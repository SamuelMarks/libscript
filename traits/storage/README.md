# Plane A Block, Network & ML Object Storage Trait (`traits/storage/`)

## Overview

`traits/storage/` binds host block devices, shared network filesystems, and high-throughput ML
object buckets to `T1` datastores and `T5` workloads in both `T3` offline sysroot bake mode and
`T4`/`T5` live host mode.

## Scripts

- **`mount.{sh,cmd}`**: Formats uninitialized volumes via `T0` `engine/common/format_fs.{sh,cmd}`,
  mounts persistent directories, and records idempotent `/etc/fstab` entries (or Windows volume
  mounts).
- **`nfs.{sh,cmd}` & `smb.{sh,cmd}`**: Configures resilient NFSv4 and SMB/CIFS shared mounts
  (including GCP Filestore, AWS EFS, and Azure Files).
- **`gcs_ml.{sh,cmd}`**: Enforces the 4-role regional Google Cloud Storage bucket architecture
  (`engine/schemas/gcs-ml-storage.schema.json`: `datasets`, `checkpoints`, `logs`, `artifacts`) in
  the exact TPU/GPU zone region to guarantee `$0.00` cross-region egress.
- **`gcsfuse.{sh,cmd}`**: Mounts GCS buckets via `_lib/storage-layers/gcsfuse` with tuned parallel
  readahead and metadata caching for ML training checkpoints and datasets.

## Usage

```sh
./libscript.sh trait apply storage
./traits/storage/gcs_ml.sh --region us-central2 --prefix my-tpu-run
```
