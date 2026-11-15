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

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MSYS2_INSTALL_METHOD` | How to install MSYS2. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `MSYS2_VERSION`        | Specific version of msys2 to install.                                                                                                                                 | `latest`           |                  |
| `MSYS2_DOWNLOAD_URL`   | Override URL for downloading msys2 binary or archive artifacts.                                                                                                       | `none`             |                  |
| `MSYS2_RELEASES_URL`   | Override URL for querying msys2 available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
