# Opam

Bootstrap script for [opam](https://opam.ocaml.org/), the source-based package manager for OCaml.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `opam` versions natively by default (`OPAM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages opam versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/opam/<version>`.
