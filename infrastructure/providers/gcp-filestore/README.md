# GCP Filestore Component

The `filestore` component manages Google Cloud Filestore (NFS) instances, providing high-throughput
shared storage for multi-node clusters (such as TPU Pods).

## Usage

```sh
./libscript.sh gcp-filestore <action> [args...]
```

### Actions

- `create <name>`: Provisions a new GCP Filestore instance named `<name>`.
- `delete <name>`: Deletes the GCP Filestore instance named `<name>`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default     | Aliases/Examples |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ----------- | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `none`      |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `none`      |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `none`      |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `none`      |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `none`      |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `none`      |                  |
| `GCP_PROJECT_ID`                       | Google Cloud Platform project ID for Filestore instance provisioning.                                       | `none`      |                  |
| `FILESTORE_ZONE`                       | Google Cloud zone where the Filestore instance is deployed.                                                 | `none`      |                  |
| `FILESTORE_TIER`                       | Service tier for Filestore instance performance and storage capacity.                                       | `BASIC_HDD` |                  |
| `FILESTORE_CAPACITY_GB`                | Allocated storage capacity for the Filestore volume in gigabytes.                                           | `1024`      |                  |
| `FILESTORE_NETWORK`                    | VPC network name connected to the Filestore instance.                                                       | `default`   |                  |
| `GCP_FILESTORE_ENABLED`                | Flag (0 or 1) indicating whether gcp-filestore is enabled in the execution plan.                            | `none`      |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
