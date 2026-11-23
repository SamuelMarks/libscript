# Tier 4 (`T4`) Infrastructure Resource: Cloud-Init Generator (`infrastructure/resources/cloudinit/`)

## Overview

Helper component for generating cloud-init configurations for nodes. Adapter-only component without
binary installer lifecycle.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure cloudinit`
(`infrastructure/resources/cloudinit/cli.{sh,cmd}`).

## Scripts

- `api.{sh,cmd}`
- `cli.{sh,cmd}`
- `env.{sh,cmd}`
- `gen_nocloud_iso.{sh,cmd}`
- `logs.{sh,cmd}`
- `setup.{sh,cmd}`
- `setup_generic.{sh,cmd}`
- `status.{sh,cmd}`
- `test.{sh,cmd}`
- `uninstall.{sh,cmd}`

## Usage

```sh
./libscript.sh infrastructure cloudinit --help
```

```cmd
.\libscript.cmd infrastructure cloudinit --help
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                | Description                                                    | Default |
| :---------------------- | :------------------------------------------------------------- | :------ |
| `LIBSCRIPT_DEVICE`      | The device path (e.g. /dev/sdf).                               | `-`     |
| `LIBSCRIPT_MOUNT_POINT` | The directory where the device should be mounted (e.g. /data). | `-`     |
| `LIBSCRIPT_FS_TYPE`     | The filesystem type (default: ext4).                           | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
