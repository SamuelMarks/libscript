# Go

Bootstrap module for the `go` package manager (enables `go install`).

## Usage

Ensures the `go` executable is available by pulling in the core `go` toolchain.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `go-pm` versions natively by default (`GO_PM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages go-pm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/go-pm/<version>`.
