# Pkg

Bootstrap module for the FreeBSD `pkg` package manager.

## Usage

Ensures the FreeBSD `pkg` executable is available by running `pkg bootstrap`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pkg` versions natively by default (`PKG_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pkg versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pkg/<version>`.
