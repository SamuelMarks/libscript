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

| Variable                               | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                                   | `none`             |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                                                                            | `none`             |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                                                                          | `none`             |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                                         | `none`             |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                                                                                      | `none`             |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                                                                                      | `none`             |                  |
| `AWS_DEFAULT_REGION`                   | AWS Default Region                                                                                                                                                  | `us-east-1`        |                  |
| `AWS_ACCESS_KEY_ID`                    | AWS Access Key ID                                                                                                                                                   | `none`             |                  |
| `AWS_SECRET_ACCESS_KEY`                | AWS Secret Access Key                                                                                                                                               | `none`             |                  |
| `AWS_INSTALL_METHOD`                   | How to install AWS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `AWS_AMI_NAME`                         | Configuration variable AWS_AMI_NAME for aws.                                                                                                                        | `none`             |                  |
| `AWS_DOWNLOAD_URL`                     | Override URL for downloading aws binary or archive artifacts.                                                                                                       | `none`             |                  |
| `AWS_RELEASES_URL`                     | Override URL for querying aws available remote releases.                                                                                                            | `none`             |                  |
| `AWS_S3_BUCKET`                        | Configuration variable AWS_S3_BUCKET for aws.                                                                                                                       | `none`             |                  |
| `AWS_VERSION`                          | Specific version of aws to install (e.g., latest, lts, or exact version).                                                                                           | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
