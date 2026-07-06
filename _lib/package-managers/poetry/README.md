# Poetry

Bootstrap script for [Poetry](https://python-poetry.org/), a tool for Python dependency management
and packaging. Requires Python 3 to be installed.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `poetry` versions natively by default
(`POETRY_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages poetry versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/poetry/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
