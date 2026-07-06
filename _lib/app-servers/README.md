# App Servers

This category contains components for running application servers (e.g., daemonized nodejs, python,
or rust applications).

## Available Components

<!-- BEGIN_COMPONENTS -->

- [nodejs-server](./nodejs-server/README.md)
- [ollama](./ollama/README.md)
- [python-server](./python-server/README.md)
- [rust-server](./rust-server/README.md)

<!-- END_COMPONENTS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
