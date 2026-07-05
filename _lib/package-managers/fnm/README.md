# Fnm

Bootstrap script for [fnm](https://github.com/Schniz/fnm), a fast and simple Node.js version
manager.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `fnm` versions natively by default (`FNM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages fnm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/fnm/<version>`.
