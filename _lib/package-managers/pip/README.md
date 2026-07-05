# Pip

Bootstrap module for the `pip` package manager.

## Usage

Ensures the `pip` executable is available. This relies on the core language toolchain (e.g.,
Python).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pip` versions natively by default (`PIP_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pip versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pip/<version>`.
