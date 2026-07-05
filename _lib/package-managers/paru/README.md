# Paru

Bootstrap module for the `paru` package manager.

## Usage

Ensures the `paru` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `paru` versions natively by default (`PARU_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages paru versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/paru/<version>`.
