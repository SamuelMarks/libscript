# Xbps

Bootstrap module for the Void Linux `xbps` package manager.

## Usage

Ensures the `xbps-install` executable is available (usually built-in on Void Linux).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `xbps` versions natively by default (`XBPS_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages xbps versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/xbps/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
