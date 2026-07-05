# Maven

Bootstrap module for the `maven` package manager/tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `maven` versions natively by default (`MAVEN_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages maven versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/maven/<version>`.
