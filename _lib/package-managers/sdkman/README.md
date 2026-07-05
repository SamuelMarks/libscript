# Sdkman

Bootstrap script for [SDKMAN!](https://sdkman.io/), a tool for managing parallel versions of
multiple Software Development Kits on most Unix based libscript_natives.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `sdkman` versions natively by default
(`SDKMAN_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages sdkman versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/sdkman/<version>`.
