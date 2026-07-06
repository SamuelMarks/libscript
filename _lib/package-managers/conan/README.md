# Conan

Bootstrap module for `conan` (C/C++ package manager).

## Usage

Ensures the `conan` executable is available. This relies on Python (`pip` or `pipx`).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `conan` versions natively by default (`CONAN_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages conan versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/conan/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
