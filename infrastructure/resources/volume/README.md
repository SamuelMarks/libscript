# Cloud Block Storage

The `volume` component provides a unified multicloud interface for managing and attaching block
storage volumes.

> **Note**: This component is an adapter-only cloud wrapper; it manages block storage lifecycle via
> cloud provider APIs and does not provide local `setup.sh`/`env.sh` binary installer lifecycles.

## Usage

```sh
libscript volume [create|delete|list|attach|detach] [--cloud aws|gcp|azure] [--volume-id id] [--size gb] [--zone zone] [--type type] [--node-id id] [--device path]
```

### Commands

- `create`: Provision a new block storage volume.
- `delete`: Delete an existing block storage volume.
- `list`: List managed block storage volumes.
- `attach`: Attach a block storage volume to a compute node.
- `detach`: Detach a block storage volume from a compute node.

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
| `LIBSCRIPT_VOLUME_NAME`                | Logical storage volume name for persistent data mounts.                                                     | `none`  |                  |
| `LIBSCRIPT_VOLUME_SIZE`                | Size of the volume in GB.                                                                                   | `none`  |                  |
| `LIBSCRIPT_VOLUME_ZONE`                | Zone/region for the volume.                                                                                 | `none`  |                  |
| `LIBSCRIPT_VOLUME_TYPE`                | Type of the volume (e.g., ssd, hdd).                                                                        | `none`  |                  |
| `LIBSCRIPT_NODE_ID`                    | Node ID to attach/detach the volume.                                                                        | `none`  |                  |
| `LIBSCRIPT_DEVICE`                     | Device path for attachment (e.g., /dev/sdf).                                                                | `none`  |                  |
| `LIBSCRIPT_VOLUME_ID`                  | Volume ID for operations like delete, attach, detach.                                                       | `none`  |                  |
| `LIBSCRIPT_AZURE_RESOURCE_GROUP`       | Azure Resource Group hosting managed disks when LIBSCRIPT_CLOUD='azure'.                                    | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
