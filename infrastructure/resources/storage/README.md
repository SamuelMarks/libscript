# Tier 4 (`T4`) Infrastructure Resource: Cloud Object Storage (`infrastructure/resources/storage/`)

## Overview

Multicloud interface for managing object storage buckets (S3, GCS, Azure Blob). Adapter-only
component without binary installer lifecycle.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure storage`
(`infrastructure/resources/storage/cli.{sh,cmd}`).

## Scripts

- `api.{sh,cmd}`
- `cli.{sh,cmd}`
- `env.{sh,cmd}`
- `logs.{sh,cmd}`
- `setup.{sh,cmd}`
- `setup_generic.{sh,cmd}`
- `status.{sh,cmd}`
- `test.{sh,cmd}`
- `uninstall.{sh,cmd}`

## Usage

```sh
./libscript.sh infrastructure storage --help
```

```cmd
.\libscript.cmd infrastructure storage --help
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default |
| :------------------------------------- | :---------------------------------------------------------------------------------------------------------- | :------ |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `-`     |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `-`     |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `-`     |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `-`     |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `-`     |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `-`     |
| `LIBSCRIPT_CLOUD`                      | Cloud provider (aws, gcp, azure).                                                                           | `-`     |
| `LIBSCRIPT_BUCKET`                     | The name of the object storage bucket.                                                                      | `-`     |
| `LIBSCRIPT_SYNC_DIR`                   | Local directory path for bucket sync operations.                                                            | `-`     |
| `LIBSCRIPT_STORAGE_PUBLIC_WEB`         | Configure the bucket for public website hosting.                                                            | `-`     |
| `LIBSCRIPT_AZURE_ACCOUNT_NAME`         | Azure Storage Account Name (required for Azure operations).                                                 | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
