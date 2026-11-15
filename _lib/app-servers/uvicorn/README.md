# Uvicorn

An ASGI web server implementation for Python with native Windows support.

## Usage

Provides `uvicorn` to execute ASGI and WSGI Python applications with native support across Linux,
macOS, FreeBSD, SunOS, and Windows.

```sh
./libscript.sh install uvicorn
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable          | Description                             | Default   | Aliases/Examples |
| ----------------- | --------------------------------------- | --------- | ---------------- |
| `UVICORN_VERSION` | Specific version of uvicorn to install. | `latest`  |                  |
| `UVICORN_WORKERS` | Number of worker processes.             | `2`       |                  |
| `UVICORN_PORT`    | TCP port to bind to.                    | `8000`    |                  |
| `UVICORN_HOST`    | Host/IP to bind to.                     | `0.0.0.0` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
