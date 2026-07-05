# Apt

Bootstrap module for the `apt` package manager.

## Usage

This module ensures `apt` is available and updated. Since `apt` is natively integrated into its
corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `apt` versions natively by default (`APT_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages apt versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/apt/<version>`.
