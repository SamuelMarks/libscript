# hMailServer

Free, open-source e-mail server for Microsoft Windows with SMTP relay support.

## Usage

Provides `hMailServer` as a native Windows service for local SMTP email delivery, used by Open edX
and Django applications running on Windows environments.

```cmd
libscript.cmd install hmailserver
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                    | Description                                                     | Default    | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------- | ---------- | ---------------- |
| `HMAILSERVER_VERSION`       | Version of hMailServer to install.                              | `5.6.8`    |                  |
| `HMAILSERVER_INSTALL_DIR`   | Destination directory for hMailServer installation.             | `none`     |                  |
| `HMAILSERVER_SMTP_PORT`     | Port for SMTP listener.                                         | `25`       |                  |
| `HMAILSERVER_DATABASE_TYPE` | Database engine used by hMailServer (e.g. 'built-in', 'mysql'). | `built-in` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
