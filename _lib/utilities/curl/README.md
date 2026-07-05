# cURL

curl is a command-line tool and library for transferring data specified with URL syntax. It supports
a large number of protocols, including HTTP, HTTPS, FTP, FTPS, SCP, SFTP, TFTP, DICT, TELNET, LDAP,
and FILE. It is widely used for API interactions, data transfer, and automated scripts.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

curl can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can manage curl using libscript with the following commands:

- **Install**: `libscript install curl`
- **Uninstall**: `libscript uninstall curl`
- **Start**: `libscript start curl`
- **Stop**: `libscript stop curl`
- **Package**: `libscript package curl`

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `curl` versions natively by default (`CURL_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages curl versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/curl/<version>`.
