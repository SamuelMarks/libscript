# Cloud Object Storage

The `storage` component provides a unified multicloud interface for managing object storage buckets
(S3, GCS, Azure Blob).

> **Note**: This component is an adapter-only cloud wrapper; it manages bucket lifecycles via cloud
> provider storage APIs and does not provide local `setup.sh`/`env.sh` binary installer lifecycles.

## Usage

```sh
libscript storage [create|delete|list|sync] [--cloud aws|gcp|azure] [--bucket name] [--local-dir path] [--public-web]
```

### Commands

- `create`: Provision a new object storage bucket.
- `delete`: Delete an existing object storage bucket.
- `list`: List managed object storage buckets.
- `sync`: Sync a local directory to an object storage bucket.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default | Aliases/Examples |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `none`  |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `none`  |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `none`  |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `none`  |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `none`  |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `none`  |                  |
| `LIBSCRIPT_CLOUD`                      | Cloud provider (aws, gcp, azure).                                                                           | `none`  |                  |
| `LIBSCRIPT_BUCKET`                     | The name of the object storage bucket.                                                                      | `none`  |                  |
| `LIBSCRIPT_SYNC_DIR`                   | Local directory path for bucket sync operations.                                                            | `none`  |                  |
| `LIBSCRIPT_STORAGE_PUBLIC_WEB`         | Configure the bucket for public website hosting.                                                            | `none`  |                  |
| `LIBSCRIPT_AZURE_ACCOUNT_NAME`         | Azure Storage Account Name (required for Azure operations).                                                 | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
