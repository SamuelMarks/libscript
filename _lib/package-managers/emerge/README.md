# Emerge

Bootstrap module for the Gentoo `emerge` package manager.

## Usage

Ensures the `emerge` executable is available (usually built-in on Gentoo).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `emerge` versions natively by default
(`EMERGE_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages emerge versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/emerge/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
