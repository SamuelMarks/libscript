Msys2
=====

MSYS2 is a collection of tools and libraries providing an easy-to-use environment for building, installing, and running native Windows software. It consists of a command-line terminal called mintty, bash, version control systems like git, and various build systems like autotools and GCC.

## Integration with Libscript
It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`.

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
- Linux
- macOS
- Windows
