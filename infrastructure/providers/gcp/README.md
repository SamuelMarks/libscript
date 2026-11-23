# Google Cloud Platform (GCP)

This module configures the `gcp` cloud provider capabilities within LibScript. It leverages the
Google Cloud SDK (`gcloud`) to provide provisioning and configuration targets for Google Cloud
Platform.

## Purpose & Current State

- Provides runtime context and authentication pathways for GCP targets.
- Serves as the foundation for multi-cloud deployments bridging to GCE, GKE, and Google Cloud
  Storage.

## Usage

Used internally by the `libscript deploy` and `libscript teardown` systems when GCP is the target
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
| `GCP_PROJECT_ID`                       | GCP Project ID                                                                                                                                        | `-`                |
| `GCP_REGION`                           | GCP Region                                                                                                                                            | `us-central1`      |
| `GCP_ZONE`                             | GCP Zone                                                                                                                                              | `us-central1-a`    |
| `GCP_INSTALL_METHOD`                   | Installation strategy for gcp: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |
| `GCP_DOWNLOAD_URL`                     | Override URL for downloading gcp binary or archive artifacts.                                                                                         | `-`                |
| `GCP_GCS_BUCKET`                       | Google Cloud Storage bucket name used for Compute Engine raw disk tarballs, image imports, or state storage.                                          | `-`                |
| `GCP_IMAGE_NAME`                       | Google Compute Engine custom machine image name registered or booted during GCP provisioning.                                                         | `-`                |
| `GCP_RELEASES_URL`                     | Override URL for querying gcp available remote releases.                                                                                              | `-`                |
| `GCP_VERSION`                          | Specific version of gcp to install (e.g., latest, lts, or exact version).                                                                             | `-`                |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
