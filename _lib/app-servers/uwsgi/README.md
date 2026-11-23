# uWSGI

**Tier**: `T1` (`_lib/app-servers/uwsgi/`) | **Capabilities**: `userland-package`, `service-daemon`

Fast, self-healing, developer-friendly WSGI server and application container.

## Usage

Provides `uwsgi` to run production Python WSGI web applications. Tutor uses `uwsgi` for Open edX LMS
and CMS with configuration from `uwsgi.ini`.

```sh
./libscript.sh install uwsgi
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                     | Default  | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------- | -------- | ---------------- |
| `UWSGI_VERSION`        | Specific version of uwsgi to install (e.g. '2.0.24', 'latest'). | `2.0.24` |                  |
| `UWSGI_INSTALL_METHOD` | How to install uwsgi ('system', 'libscript_native').            | `system` |                  |
| `UWSGI_WORKERS`        | Default amount of uWSGI processes.                              | `2`      |                  |
| `UWSGI_INI`            | Path to uwsgi.ini configuration file.                           | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
