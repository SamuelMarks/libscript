# Init Systems

This category contains components for configuring and interacting with init systems like systemd and
OpenRC.

## Available Components

<!-- BEGIN_COMPONENTS -->

- [openrc](./openrc/README.md)
- [systemd](./systemd/README.md)

<!-- END_COMPONENTS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
