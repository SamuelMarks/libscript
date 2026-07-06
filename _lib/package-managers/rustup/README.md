# Rustup

Bootstrap module for `rustup` (Rust toolchain installer).

## Usage

Ensures the `rustup` executable is available for managing Rust toolchains and supplementary cargo
components.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `rustup` versions natively by default
(`RUSTUP_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages rustup versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/rustup/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
