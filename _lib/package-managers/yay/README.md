# Yay

Bootstrap module for the `yay` package manager.

## Usage

Ensures the `yay` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `yay` versions natively by default (`YAY_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages yay versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/yay/<version>`.
