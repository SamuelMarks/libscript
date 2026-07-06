# Pdm

Bootstrap module for `pdm` (Modern Python package and dependency manager).

## Usage

Ensures the `pdm` executable is available. Relies on `pipx` or standard Python `pip`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pdm` versions natively by default (`PDM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pdm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pdm/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
