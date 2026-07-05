# Vcpkg

Bootstrap module for the `vcpkg` package manager/tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `vcpkg` versions natively by default (`VCPKG_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages vcpkg versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/vcpkg/<version>`.
