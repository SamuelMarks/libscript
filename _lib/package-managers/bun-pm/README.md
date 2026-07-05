# Bun

Bootstrap script for [Bun](https://bun.sh), a fast all-in-one JavaScript runtime, bundler, test
runner, and package manager.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `bun-pm` versions natively by default
(`BUN_PM_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages bun-pm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/bun-pm/<version>`.
