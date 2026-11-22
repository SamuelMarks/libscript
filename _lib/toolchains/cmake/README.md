# Cmake

Cross-platform family of tools designed to build, test and package software.

## Usage

```sh
libscript install cmake latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                           | Default  | Aliases/Examples |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CMAKE_VERSION`            | Specific version of cmake to install. Can be a numeric version or an alias.                                                                                           | `latest` | latest, stable   |
| `CMAKE_INSTALL_METHOD`     | How to install CMAKE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                              | `none`   |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                                           | `none`   |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                                       | `none`   |                  |
| `CMAKE_LISTEN_PORT`        | Port for CMAKE to listen on                                                                                                                                           | `none`   |                  |
| `CMAKE_LISTEN_ADDRESS`     | Address for CMAKE to listen on                                                                                                                                        | `none`   |                  |
| `CMAKE_LISTEN_SOCKET`      | Unix socket for CMAKE to listen on                                                                                                                                    | `none`   |                  |
| `CMAKE_DOWNLOAD_URL`       | Override URL for downloading cmake binary or archive artifacts.                                                                                                       | `none`   |                  |
| `CMAKE_RELEASES_URL`       | Override URL for querying cmake available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
