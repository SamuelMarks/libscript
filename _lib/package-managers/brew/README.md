# Brew

Homebrew is a free and open-source software package management libscript_native that simplifies the
installation of software on macOS and Linux. It builds packages from source and provides
pre-compiled binaries, making it easy to manage dependencies and development tools.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

Homebrew can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud,
etc.).

## Usage

You can manage Homebrew using libscript with the following commands:

- **Install**: `libscript install brew`
- **Uninstall**: `libscript uninstall brew`
- **Start**: `libscript start brew`
- **Stop**: `libscript stop brew`
- **Package**: `libscript package brew`

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BREW_INSTALL_METHOD` | How to install BREW. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `BREW_VERSION`        | Specific version of brew to install.                                                                                                                                 | `latest`           |                  |
| `BREW_DOWNLOAD_URL`   | Override URL for downloading brew binary or archive artifacts.                                                                                                       | `none`             |                  |
| `BREW_RELEASES_URL`   | Override URL for querying brew available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
