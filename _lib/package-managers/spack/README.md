# Spack

Bootstrap script for [Spack](https://spack.io/), a flexible package manager that supports multiple
versions, configurations, platforms, and compilers.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `spack` versions natively by default (`SPACK_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages spack versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/spack/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
