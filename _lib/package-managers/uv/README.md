# Uv

Bootstrap module for the `uv` package manager (astral.sh).

## Usage

Installs the `uv` executable via its standalone installer.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `uv` versions natively by default (`UV_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages uv versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/uv/<version>`.
