# Conda

Bootstrap module for the `conda` package manager via Miniconda.

## Usage

Downloads and installs Miniconda3 non-interactively to `~/miniconda3`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `conda` versions natively by default (`CONDA_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages conda versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/conda/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
