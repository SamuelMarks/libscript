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

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `wget` versions natively by default (`WGET_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages wget versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/wget/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
