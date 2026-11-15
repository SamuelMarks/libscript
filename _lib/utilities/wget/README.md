# wget

GNU Wget is a free software package for retrieving files using HTTP, HTTPS, FTP, and FTPS, the most
widely used Internet protocols. It is a non-interactive command-line tool, so it may easily be
called from scripts, cron jobs, or terminals without X-Windows support.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

wget can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

_Note: libscript manages versions natively for this component._

You can manage wget using libscript with the following commands:

- **Install**: `libscript install wget`
- **Uninstall**: `libscript uninstall wget`
- **Start**: `libscript start wget`
- **Stop**: `libscript stop wget`
- **Package**: `libscript package wget`

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default  | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `WGET_INSTALL_METHOD` | How to install WGET. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `WGET_VERSION`        | Specific version of wget to install.                                                                                                                                 | `latest` |                  |
| `WGET_DOWNLOAD_URL`   | Override URL for downloading wget binary or archive artifacts.                                                                                                       | `none`   |                  |
| `WGET_RELEASES_URL`   | Override URL for querying wget available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
