# Dnf

Bootstrap module for the `dnf` package manager.

## Usage

This module ensures `dnf` is available and updated. Since `dnf` is natively integrated into its
corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `dnf` versions natively by default (`DNF_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages dnf versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/dnf/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
