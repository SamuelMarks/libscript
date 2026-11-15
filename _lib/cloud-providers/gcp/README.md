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

| Variable                               | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                                                                                   | `none`             |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                                                                            | `none`             |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                                                                          | `none`             |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters.                                                         | `none`             |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                                                                                      | `none`             |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                                                                                      | `none`             |                  |
| `GCP_PROJECT_ID`                       | GCP Project ID                                                                                                                                                      | `none`             |                  |
| `GCP_REGION`                           | GCP Region                                                                                                                                                          | `us-central1`      |                  |
| `GCP_ZONE`                             | GCP Zone                                                                                                                                                            | `us-central1-a`    |                  |
| `GCP_INSTALL_METHOD`                   | How to install GCP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `GCP_DOWNLOAD_URL`                     | Override URL for downloading gcp binary or archive artifacts.                                                                                                       | `none`             |                  |
| `GCP_GCS_BUCKET`                       | Configuration variable GCP_GCS_BUCKET for gcp.                                                                                                                      | `none`             |                  |
| `GCP_IMAGE_NAME`                       | Configuration variable GCP_IMAGE_NAME for gcp.                                                                                                                      | `none`             |                  |
| `GCP_RELEASES_URL`                     | Override URL for querying gcp available remote releases.                                                                                                            | `none`             |                  |
| `GCP_VERSION`                          | Specific version of gcp to install (e.g., latest, lts, or exact version).                                                                                           | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
