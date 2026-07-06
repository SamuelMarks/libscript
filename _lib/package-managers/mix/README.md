# Mix

Bootstrap module for `mix` (Elixir package manager and build tool).

## Usage

Ensures the `mix` executable is available by leveraging the core Elixir toolchain.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `mix` versions natively by default (`MIX_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages mix versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/mix/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
