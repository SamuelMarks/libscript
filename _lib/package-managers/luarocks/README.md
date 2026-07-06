# Luarocks

Bootstrap script for [LuaRocks](https://luarocks.org/), the package manager for Lua modules.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `luarocks` versions natively by default
(`LUAROCKS_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting
global system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if
preferred.

Libscript manages luarocks versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/luarocks/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
