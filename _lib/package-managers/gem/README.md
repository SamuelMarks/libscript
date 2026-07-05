# Gem

Bootstrap module for the `gem` package manager.

## Usage

Ensures the `gem` executable is available. This relies on the core language toolchain (e.g., Ruby).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `gem` versions natively by default (`GEM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages gem versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/gem/<version>`.
