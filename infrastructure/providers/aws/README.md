# Amazon Web Services (AWS)

This module configures the `aws` cloud provider capabilities within LibScript. It leverages the AWS
CLI and associated tools to provide provisioning and configuration targets for Amazon Web Services.

## Purpose & Current State

- Provides runtime context and authentication pathways for AWS targets.
- Serves as the foundation for multi-cloud deployments bridging to EC2, EKS, and S3 resources.

## Usage

Used internally by the `libscript deploy` and `libscript teardown` systems when AWS is the target
provider.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                                                           | Default            |
| :------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                     | `-`                |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                                                              | `-`                |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                                                            | `-`                |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                           | `-`                |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                                                                        | `-`                |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                                                                        | `-`                |
| `AWS_DEFAULT_REGION`                   | AWS Default Region                                                                                                                                    | `us-east-1`        |
| `AWS_ACCESS_KEY_ID`                    | AWS Access Key ID                                                                                                                                     | `-`                |
| `AWS_SECRET_ACCESS_KEY`                | AWS Secret Access Key                                                                                                                                 | `-`                |
| `AWS_INSTALL_METHOD`                   | Installation strategy for aws: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |
| `AWS_AMI_NAME`                         | Target Amazon Machine Image (AMI) name registered or looked up during AWS EC2 provisioning and image import.                                          | `-`                |
| `AWS_DOWNLOAD_URL`                     | Override URL for downloading aws binary or archive artifacts.                                                                                         | `-`                |
| `AWS_RELEASES_URL`                     | Override URL for querying aws available remote releases.                                                                                              | `-`                |
| `AWS_S3_BUCKET`                        | Amazon S3 bucket name used for VM Import/Export staging, state artifacts, or backup blobs.                                                            | `-`                |
| `AWS_VERSION`                          | Specific version of aws to install (e.g., latest, lts, or exact version).                                                                             | `-`                |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
