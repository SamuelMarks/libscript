# Deno

Bootstrap script for [Deno](https://deno.land), a modern and secure runtime for JavaScript and
TypeScript that uses V8 and is built in Rust.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `deno-pm` versions natively by default
(`DENO_PM_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting
global system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if
preferred.

Libscript manages deno-pm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/deno-pm/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
