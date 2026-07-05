# Hatch

Bootstrap module for `hatch` (Modern Python project manager).

## Usage

Ensures the `hatch` executable is available. Relies on `pipx` or standard Python `pip`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `hatch` versions natively by default (`HATCH_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages hatch versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/hatch/<version>`.
