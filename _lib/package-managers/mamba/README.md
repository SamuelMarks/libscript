# Mamba

Bootstrap module for the `mamba` package manager.

## Usage

Ensures the `mamba` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `mamba` versions natively by default (`MAMBA_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages mamba versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/mamba/<version>`.
