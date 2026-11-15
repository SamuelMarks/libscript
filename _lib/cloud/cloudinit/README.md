# Cloud-Init Generator

The `cloudinit` component provides a helper for generating `#cloud-config` YAML blocks, specifically
for automating block volume mounting.

> **Note**: This component is an adapter-only generator utility; it renders declarative cloud-init
> templates and does not provide local `setup.sh`/`env.sh` binary installer lifecycles.

## Usage

```sh
libscript cloudinit generate-mount [--device path] [--mount-point path] [--fs-type type]
```

### Commands

- `generate-mount`: Outputs valid cloud-init YAML to partition, format, and mount a block device.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                | Description                                                    | Default | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------- | ------- | ---------------- |
| `LIBSCRIPT_DEVICE`      | The device path (e.g. /dev/sdf).                               | `none`  |                  |
| `LIBSCRIPT_MOUNT_POINT` | The directory where the device should be mounted (e.g. /data). | `none`  |                  |
| `LIBSCRIPT_FS_TYPE`     | The filesystem type (default: ext4).                           | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
