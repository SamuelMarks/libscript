# Pub

Bootstrap module for `pub` (Dart / Flutter package manager).

## Usage

Ensures the `pub` executable (or `dart pub`) is available. This relies on the core Dart toolchain.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pub` versions natively by default (`PUB_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pub versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pub/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
