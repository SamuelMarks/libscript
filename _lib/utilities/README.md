# Utilities

This category contains general-purpose system utilities, CLI tools, and basic dependencies (e.g.,
curl, jq, 7zip).

## Available Components

<!-- BEGIN_COMPONENTS -->

- [7zip](./7zip/README.md)
- [aria2](./aria2/README.md)
- [busybox](./busybox/README.md)
- [curl](./curl/README.md)
- [dash](./dash/README.md)
- [jq](./jq/README.md)
- [powershell](./powershell/README.md)
- [wait4x](./wait4x/README.md)
- [wget](./wget/README.md)

<!-- END_COMPONENTS -->

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
