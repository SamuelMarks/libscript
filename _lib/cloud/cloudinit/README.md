# Cloud-Init Generator

The `cloudinit` component provides a helper for generating `#cloud-config` YAML blocks, specifically
for automating block volume mounting.

## Usage

```sh
libscript cloudinit generate-mount [--device path] [--mount-point path] [--fs-type type]
```

### Commands

- `generate-mount`: Outputs valid cloud-init YAML to partition, format, and mount a block device.
