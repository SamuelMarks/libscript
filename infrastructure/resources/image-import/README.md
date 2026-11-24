# Tier 4 (`T4`) Infrastructure Resource: Multicloud UEFI Appliance & Distro Image Importer (`infrastructure/resources/image-import/`)

## Overview

Idempotent cloud object-storage upload and VM/distro/unikernel image registration across AWS EC2
AMI, GCP Shielded Compute Image, and Azure Managed Image (plus optional Azure Compute Gallery Gen2
VHD), accepting artifacts emitted directly by
`./libscript.sh package-as {linux,freebsd,illumos,reactos,unikernel}-distro`.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure image-import`
(`infrastructure/resources/image-import/cli.{sh,cmd}`).

## Scripts

- `aws_import.{sh,cmd}`
- `azure_import.{sh,cmd}`
- `cli.{sh,cmd}`
- `distro_import.{sh,cmd}`
- `gcp_import.{sh,cmd}`
- `test.{sh,cmd}`

## Usage

```sh
# Register an artifact emitted by package-as across AWS AMI, GCP Compute Image, and Azure Managed Image
./libscript.sh package-as linux-distro --profile linux-minimal-headless-musl --format raw --output ./build/linux.raw --allow-stub
./libscript.sh infrastructure image-import distro --disk=./build/linux.raw --clouds=aws,gcp,azure --dry-run

# Or synthesize and register in a single idempotent command
./libscript.sh infrastructure image-import distro --distro=freebsd-distro --profile=minimal-server --clouds=aws,gcp,azure --dry-run --allow-stub
```

```cmd
.\libscript.cmd infrastructure image-import distro --distro=linux-distro --profile=linux-minimal-headless-musl --clouds=aws,gcp,azure --dry-run --allow-stub
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                         | Default                    |
| :--------------------------- | :------------------------------------------------------------------------------------------------------------------ | :------------------------- |
| `IMAGE_IMPORT_DRY_RUN`       | Flag (0 or 1) emitting cloud import descriptors without invoking live cloud APIs.                                   | `0`                        |
| `IMAGE_IMPORT_ARCH`          | Target CPU architecture registered on the imported cloud VM image.                                                  | `x86_64`                   |
| `IMAGE_IMPORT_AWS_BUCKET`    | Default Amazon S3 bucket used to stage disk snapshots prior to EC2 AMI registration.                                | `libscript-ami-staging`    |
| `IMAGE_IMPORT_AWS_REGION`    | Target AWS EC2 region for snapshot import and AMI registration.                                                     | `us-east-1`                |
| `IMAGE_IMPORT_GCP_BUCKET`    | Default Google Cloud Storage bucket used to stage disk.raw.tar.gz archives.                                         | `libscript-gce-staging`    |
| `IMAGE_IMPORT_GCP_PROJECT`   | Target Google Cloud Platform project ID for GCE Compute Image registration.                                         | `libscript-cloud`          |
| `IMAGE_IMPORT_AZURE_ACCOUNT` | Default Azure Blob Storage account used for 1 MiB-aligned VHD PageBlob uploads.                                     | `libscriptvhd`             |
| `IMAGE_IMPORT_AZURE_RG`      | Target Azure Resource Group for Managed Image and Compute Gallery resources.                                        | `libscript-marketplace-rg` |
| `IMAGE_IMPORT_AZURE_GALLERY` | Optional Azure Compute Gallery (Shared Image Gallery) name; when empty, registers a standalone Azure Managed Image. | ``                         |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
