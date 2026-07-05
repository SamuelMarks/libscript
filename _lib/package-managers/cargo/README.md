# Cargo

Bootstrap module for the `cargo` package manager.

## Usage

Ensures the `cargo` executable is available. This relies on the core language toolchain (e.g.,
Rust).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `cargo` versions natively by default (`CARGO_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages cargo versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/cargo/<version>`.
