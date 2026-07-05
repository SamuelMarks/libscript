# Sbt

Bootstrap module for the `sbt` package manager.

## Usage

Ensures the `sbt` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `sbt` versions natively by default (`SBT_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages sbt versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/sbt/<version>`.
