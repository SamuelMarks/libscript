# SQLite

## Purpose & Current State

This document provides context and technical details for the **SQLite** component (part of the
`_storage` module) within the LibScript ecolibscript_native. SQLite is a C-language library that
implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine.

This component works both as a local version manager for SQLite (similar to `rvm`, `nvm`, `pyenv`,
or `uv`) and can be natively invoked from the global version manager `libscript`. Because of this
flexibility, SQLite can be used by LibScript to provision and build bigger, more complex software
stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can install, start, stop, package, and uninstall sqlite using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install sqlite

./cli.sh install sqlite

./libscript.sh start sqlite
./cli.sh start sqlite

./libscript.sh stop sqlite
./cli.sh stop sqlite

./libscript.sh package-as docker sqlite
./cli.sh package-as docker sqlite

./libscript.sh uninstall sqlite
./cli.sh uninstall sqlite
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install sqlite

:: Local CLI
cli.cmd install sqlite

:: Start and Stop
libscript.cmd start sqlite
cli.cmd start sqlite

libscript.cmd stop sqlite
cli.cmd stop sqlite

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi sqlite
cli.cmd package-as msi sqlite

:: Uninstall
libscript.cmd uninstall sqlite
cli.cmd uninstall sqlite
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                                                                         | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`                                                              |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                                                                          |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                                                                       |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                                                                          |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                                                                          |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                                                                          |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                                                                        |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                                                                             |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                                                                          |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                                                                          |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                                                                          |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                                                                          |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                                                                          |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                                                                          |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                                                                             |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                                                                             |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                                                                          |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                                                                          |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                                                                          |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                                                                          |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                                                                          |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                                                                          |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                                                                          |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                                                                          |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                                                                          |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`                                                                 |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                                                                          |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`                                                           |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                                                                          |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                                                                          |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                                                                             |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name`                                                      |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                                                                          |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                                                                          |                  |
| `SQLITE_VERSION`                   | Specific version of SQLite to install or compile (e.g., '3.46.1' or 'latest').                                                                                                                                                                                                                                                  | `latest`                                                                        | latest, stable   |
| `SQLITE_INSTALL_METHOD`            | How to install SQLite ('libscript_native' prebuilt binary, 'from-source' compiled from the C amalgamation, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                                          | `libscript_native`                                                              |                  |
| `SQLITE_PKG_MGR`                   | Specific package manager to use when installing SQLite via package manager (e.g., apt-get, apk, dnf, brew, winget, choco, scoop, nix, vcpkg).                                                                                                                                                                                   | `none`                                                                          |                  |
| `SQLITE_BUILD_TOOLCHAIN`           | Build toolchain used when SQLITE_INSTALL_METHOD='from-source' ('default' uses platform default C compiler; 'gcc', 'clang', 'tcc', 'custom-cc', or a binary path uses that custom compiler).                                                                                                                                     | `default`                                                                       |                  |
| `SQLITE_COMPILER`                  | Alias for SQLITE_BUILD_TOOLCHAIN specifying the C compiler for source builds.                                                                                                                                                                                                                                                   | `default`                                                                       |                  |
| `SQLITE_CFLAGS`                    | Compiler flags passed when compiling the SQLite amalgamation from source.                                                                                                                                                                                                                                                       | `-O2 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE` |                  |
| `SQLITE_LDFLAGS`                   | Linker flags passed when linking the SQLite CLI and library from source.                                                                                                                                                                                                                                                        | `-lpthread -ldl -lm`                                                            |                  |
| `SQLITE_SINGLE_THREADED`           | When true, compiles SQLite with -DSQLITE_THREADSAFE=0 and -DSQLITE_OMIT_LOAD_EXTENSION=1 for minimal C compilers.                                                                                                                                                                                                               | `none`                                                                          |                  |
| `SQLITE_AMALGAMATION_URL`          | Optional explicit download URL for the SQLite C amalgamation archive.                                                                                                                                                                                                                                                           | `none`                                                                          |                  |
| `SQLITE_AMALGAMATION_YEAR`         | Release year directory on sqlite.org used when constructing the default amalgamation URL.                                                                                                                                                                                                                                       | `2024`                                                                          |                  |
| `SQLITE_BUILD_SHARED_LIB`          | Whether to also compile the shared library (libsqlite3.so / libsqlite3.dylib / sqlite3.dll) during from-source builds.                                                                                                                                                                                                          | `true`                                                                          |                  |
| `LIBSCRIPT_LISTEN_PORT`            | Global port to listen on                                                                                                                                                                                                                                                                                                        | `none`                                                                          |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`         | Global address to listen on                                                                                                                                                                                                                                                                                                     | `none`                                                                          |                  |
| `LIBSCRIPT_LISTEN_SOCKET`          | Global unix socket to listen on                                                                                                                                                                                                                                                                                                 | `none`                                                                          |                  |
| `SQLITE_LISTEN_PORT`               | Port for SQLITE to listen on                                                                                                                                                                                                                                                                                                    | `none`                                                                          |                  |
| `SQLITE_LISTEN_ADDRESS`            | Address for SQLITE to listen on                                                                                                                                                                                                                                                                                                 | `none`                                                                          |                  |
| `SQLITE_LISTEN_SOCKET`             | Unix socket for SQLITE to listen on                                                                                                                                                                                                                                                                                             | `none`                                                                          |                  |

<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh` / `setup_generic.cmd`: Multi-mode provisioner supporting Mode 1
  (`--pkg-mgr=<pm>`), Mode 2 (`--from-source --toolchain=default`), and Mode 3
  (`--from-source --toolchain=gcc|clang|tcc|custom-cc`).
- `test.sh` / `test.cmd`: 6-stage relational SQL torture suite with deterministic SHA-256 output
  digest verification.
- `compare_compilers.sh` / `compare_compilers.cmd`: 4-way differential C compiler benchmark and
  verification harness (`build/sqlite-compiler-comparison.json`).
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
