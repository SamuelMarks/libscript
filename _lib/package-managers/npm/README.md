# Npm

Bootstrap module for the `npm` package manager.

## Usage

Ensures the `npm` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `npm` versions natively by default (`NPM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages npm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/npm/<version>`.
