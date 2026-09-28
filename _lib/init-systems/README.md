# Init Systems

This category contains components for configuring and interacting with init systems like systemd and
OpenRC.

## Available Components

<!-- BEGIN_COMPONENTS -->

- [dinit](./dinit/README.md)
- [openrc](./openrc/README.md)
- [runit](./runit/README.md)
- [s6](./s6/README.md)
- [systemd](./systemd/README.md)
- [sysvinit](./sysvinit/README.md)

<!-- END_COMPONENTS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
