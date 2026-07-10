# Cloud Block Storage

The `volume` component provides a unified multicloud interface for managing and attaching block
storage volumes.

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
