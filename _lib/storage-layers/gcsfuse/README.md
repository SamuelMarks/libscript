# gcsfuse Component

## Overview

This component manages the installation and execution of Google Cloud Storage FUSE (`gcsfuse`)
within the libscript ecolibscript_native. It allows you to mount GCS buckets as local file
libscript_natives, which is critical for large ML workloads to read datasets and write checkpoints
without filling up local disk space.

## Usage

Refer to the component's setup and cli scripts for specific operations.

```bash
# Mount a bucket
./_lib/storage-layers/gcsfuse/cli.sh mount gs://my-bucket /mnt/my-bucket

# Unmount
./_lib/storage-layers/gcsfuse/cli.sh unmount /mnt/my-bucket
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

Libscript manages gcsfuse versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/gcsfuse/<version>`.

## Configuration

| Variable                 | Description                                                                                                                                                             | Default            | Required |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `GCSFUSE_INSTALL_METHOD` | How to install GCSFUSE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |
