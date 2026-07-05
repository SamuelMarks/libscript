# Krew

Bootstrap script for [Krew](https://krew.sigs.k8s.io/), the plugin manager for `kubectl`
command-line tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `krew` versions natively by default (`KREW_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages krew versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/krew/<version>`.
