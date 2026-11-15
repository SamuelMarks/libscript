# Waitress

Production-quality pure-Python WSGI server with native Windows support.

## Usage

Provides `waitress-serve` to run WSGI web applications (such as Open edX LMS and Studio) across all
operating systems without requiring POSIX `fork()`. Ideal for running Open edX on Windows.

```sh
./libscript.sh install waitress
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable               | Description                                              | Default   | Aliases/Examples |
| ---------------------- | -------------------------------------------------------- | --------- | ---------------- |
| `WAITRESS_VERSION`     | Specific version of waitress to install.                 | `latest`  |                  |
| `WAITRESS_THREADS`     | Number of worker threads used to process requests.       | `4`       |                  |
| `WAITRESS_PORT`        | TCP port to bind to.                                     | `8000`    |                  |
| `WAITRESS_LISTEN_PORT` | Port for Waitress to listen on (alias of WAITRESS_PORT). | `8000`    |                  |
| `WAITRESS_HOST`        | Host/IP to bind to.                                      | `0.0.0.0` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
