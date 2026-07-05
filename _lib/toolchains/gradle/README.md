# Gradle

Bootstrap module for `gradle` (Java / JVM build automation system).

## Usage

_Note: libscript manages versions natively for this component._

Ensures the `gradle` executable is available. Relies on the core Java toolchain and commonly uses
`sdkman` to manage versions on UNIX-like environments.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `gradle` versions natively by default
(`GRADLE_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages gradle versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/gradle/<version>`.
