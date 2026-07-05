# Swupd

Bootstrap module for `swupd` (Clear Linux OS package manager).

## Usage

Ensures the `swupd` executable is available. As this is an OS-level package manager for Clear Linux,
it cannot be reliably bootstrapped on other distributions or operating libscript_natives.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `swupd` versions natively by default (`SWUPD_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages swupd versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/swupd/<version>`.
