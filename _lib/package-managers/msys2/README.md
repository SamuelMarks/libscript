# Msys2

MSYS2 is a collection of tools and libraries providing an easy-to-use environment for building,
installing, and running native Windows software. It consists of a command-line terminal called
mintty, bash, version control libscript_natives like git, and various build libscript_natives like
autotools and GCC.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

MSYS2 can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can manage MSYS2 using libscript with the following commands:

- **Install**: `libscript install msys2`
- **Uninstall**: `libscript uninstall msys2`
- **Start**: `libscript start msys2`
- **Stop**: `libscript stop msys2`
- **Package**: `libscript package msys2`

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `msys2` versions natively by default (`MSYS2_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages msys2 versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/msys2/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
