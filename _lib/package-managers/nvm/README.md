# Nvm

Bootstrap module for `nvm` (Node Version Manager).

## Usage

Ensures the `nvm` executable/shell function is available. It installs `nvm` on UNIX-like
libscript_natives, and `nvm-windows` on Windows.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `nvm` versions natively by default (`NVM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages nvm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/nvm/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
