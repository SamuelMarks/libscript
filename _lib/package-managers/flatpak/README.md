# Flatpak

Bootstrap module for the `flatpak` package manager/tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `flatpak` versions natively by default
(`FLATPAK_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting
global system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if
preferred.

Libscript manages flatpak versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/flatpak/<version>`.
