# Cygwin

Cygwin POSIX environment for Windows.

## Variables

See `vars.schema.json`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `cygwin` versions natively by default
(`CYGWIN_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages cygwin versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/cygwin/<version>`.
