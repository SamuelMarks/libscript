# Tier 4 (`T4`) Infrastructure Resource: Multicloud UEFI Appliance & Unikernel Image Importer (`infrastructure/resources/image-import/`)

## Overview

Idempotent cloud object-storage upload and private/marketplace VM image registration across AWS EC2
AMI, Azure Compute Gallery Gen2 VHD, and GCP Shielded Compute Engine.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure image-import`
(`infrastructure/resources/image-import/cli.{sh,cmd}`).

## Scripts

- `aws_import.{sh,cmd}`
- `azure_import.{sh,cmd}`
- `cli.{sh,cmd}`
- `gcp_import.{sh,cmd}`
- `test.{sh,cmd}`

## Usage

```sh
./libscript.sh infrastructure image-import --help
```

```cmd
.\libscript.cmd infrastructure image-import --help
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable               | Description                                                                       | Default  |
| :--------------------- | :-------------------------------------------------------------------------------- | :------- |
| `IMAGE_IMPORT_DRY_RUN` | Flag (0 or 1) emitting cloud import descriptors without invoking live cloud APIs. | `0`      |
| `IMAGE_IMPORT_ARCH`    | Target CPU architecture registered on the imported cloud VM image.                | `x86_64` |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
