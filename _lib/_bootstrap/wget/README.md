# wget

GNU Wget is a free software package for retrieving files using HTTP, HTTPS, FTP, and FTPS, the most widely used Internet protocols. It is a non-interactive command-line tool, so it may easily be called from scripts, cron jobs, or terminals without X-Windows support.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`.

wget can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can manage wget using libscript with the following commands:

- **Install**: `libscript install wget`
- **Uninstall**: `libscript uninstall wget`
- **Start**: `libscript start wget`
- **Stop**: `libscript stop wget`
- **Package**: `libscript package wget`

## Variables

See `vars.schema.json` for details on available variables.
