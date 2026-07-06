# R

Bootstrap module for the `R` package manager.

## Usage

Ensures the `R` executable is available. This relies on the core language toolchain appropriate for
the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `r` versions natively by default (`R_INSTALL_METHOD=libscript_native`), ensuring
isolated installations without polluting global system paths. You can override this to use `system`,
`mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages r versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/r/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
