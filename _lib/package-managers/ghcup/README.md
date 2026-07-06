# Ghcup

Bootstrap script for [GHCup](https://www.haskell.org/ghcup/), the main installer for the Haskell
language toolchain (including `cabal` and `stack`).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `ghcup` versions natively by default (`GHCUP_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages ghcup versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/ghcup/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
