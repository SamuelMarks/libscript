# Nimble

Bootstrap script for [Nimble](https://github.com/nim-lang/nimble), the package manager for the Nim
programming language. Typically installed via `choosenim`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `nimble` versions natively by default
(`NIMBLE_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages nimble versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/nimble/<version>`.
