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

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
