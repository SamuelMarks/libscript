# Pipx

Bootstrap module for the `pipx` package manager.

## Usage

Ensures the `pipx` executable is available for installing Python CLI tools in isolated environments.
This module relies on the core Python toolchain and `pip`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pipx` versions natively by default (`PIPX_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pipx versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pipx/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
