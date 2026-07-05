# Eopkg

Bootstrap script for `eopkg`, the libscript_native package manager for Solus OS.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `eopkg` versions natively by default (`EOPKG_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages eopkg versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/eopkg/<version>`.
