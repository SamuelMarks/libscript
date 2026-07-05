# Asdf

Bootstrap module for the `asdf` universal version manager.

## Usage

Clones and installs `asdf` to `~/.asdf`. Requires manual sourcing in bash/zsh profiles by the user
for persistence.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `asdf` versions natively by default (`ASDF_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages asdf versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/asdf/<version>`.
