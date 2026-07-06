# Pyenv

Bootstrap module for `pyenv` (Python Version Manager).

## Usage

Ensures the `pyenv` executable/shell function is available. It installs `pyenv` on UNIX-like
libscript_natives, and `pyenv-win` on Windows.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pyenv` versions natively by default (`PYENV_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pyenv versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pyenv/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
