# Cloud Core

This category contains core components and utilities for cloud deployments.

## Available Components

<!-- BEGIN_COMPONENTS -->

- [cdn](./cdn/README.md)
- [cert](./cert/README.md)
- [cloudinit](./cloudinit/README.md)
- [core](./core/README.md)
- [storage](./storage/README.md)
- [volume](./volume/README.md)

<!-- END_COMPONENTS -->

## Version Management

As outlined in the core philosophy, `libscript` manages versions natively. Note that cloud wrapper
components (`cdn`, `cert`, `cloudinit`, `storage`, `volume`) operate as **adapter-only** interfaces;
they provide CLI and API management wrappers around cloud provider APIs (AWS, GCP, Azure) rather
than managing local binary installer lifecycles (`setup.sh`/`env.sh`).
