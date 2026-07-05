# Julia

Bootstrap module for the `julia` package manager.

## Usage

Ensures the `julia` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `julia` versions natively by default (`JULIA_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages julia versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/julia/<version>`.
