# Mas

Bootstrap module for the `mas` package manager (Mac App Store command line interface).

## Usage

Ensures the `mas` executable is available for automating Mac App Store installs.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `mas` versions natively by default (`MAS_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages mas versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/mas/<version>`.
