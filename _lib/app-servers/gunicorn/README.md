# Gunicorn

Python WSGI HTTP Server for UNIX / POSIX.

## Usage

Provides `gunicorn` to run production Python WSGI web applications (such as Open edX LMS and
Studio/CMS).

```sh
./libscript.sh install gunicorn
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                        | Default        | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------ | -------------- | ---------------- |
| `GUNICORN_VERSION`        | Specific version of gunicorn to install (e.g. '26.2.0', 'latest'). | `latest`       |                  |
| `GUNICORN_INSTALL_METHOD` | How to install gunicorn ('system', 'libscript_native').            | `system`       |                  |
| `GUNICORN_WORKERS`        | Number of worker processes for handling requests.                  | `2`            |                  |
| `GUNICORN_BIND`           | Socket to bind (e.g. '0.0.0.0:8000', '127.0.0.1:8000').            | `0.0.0.0:8000` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
