# Tier 4 (`T4`) Infrastructure Resource: Cloud Block Storage (`infrastructure/resources/volume/`)

## Overview

Multicloud interface for managing and attaching block storage volumes. Adapter-only component
without binary installer lifecycle.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure volume`
(`infrastructure/resources/volume/cli.{sh,cmd}`).

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
./libscript.sh infrastructure volume --help
```

```cmd
.\libscript.cmd infrastructure volume --help
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
| `LIBSCRIPT_VOLUME_NAME`                | Logical storage volume name for persistent data mounts.                                                     | `-`     |
| `LIBSCRIPT_VOLUME_SIZE`                | Size of the volume in GB.                                                                                   | `-`     |
| `LIBSCRIPT_VOLUME_ZONE`                | Zone/region for the volume.                                                                                 | `-`     |
| `LIBSCRIPT_VOLUME_TYPE`                | Type of the volume (e.g., ssd, hdd).                                                                        | `-`     |
| `LIBSCRIPT_NODE_ID`                    | Node ID to attach/detach the volume.                                                                        | `-`     |
| `LIBSCRIPT_DEVICE`                     | Device path for attachment (e.g., /dev/sdf).                                                                | `-`     |
| `LIBSCRIPT_VOLUME_ID`                  | Volume ID for operations like delete, attach, detach.                                                       | `-`     |
| `LIBSCRIPT_AZURE_RESOURCE_GROUP`       | Azure Resource Group hosting managed disks when LIBSCRIPT_CLOUD='azure'.                                    | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
