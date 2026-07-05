# Guix

Bootstrap module for the `guix` (GNU Guix) package manager.

## Usage

Downloads and installs the official `guix-install.sh` script non-interactively. Requires `sudo`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `guix` versions natively by default (`GUIX_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages guix versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/guix/<version>`.
