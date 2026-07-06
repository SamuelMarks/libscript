# Composer

Bootstrap module for the `composer` package manager.

## Usage

Ensures the `composer` executable is available by delegating to the `_toolchain/composer` module.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `composer` versions natively by default
(`COMPOSER_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting
global system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if
preferred.

Libscript manages composer versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/composer/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
