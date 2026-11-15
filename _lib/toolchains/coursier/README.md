# Coursier

Pure Scala Artifact Fetching.

## Usage

_Note: libscript manages versions natively for this component._

```sh
libscript install coursier latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                              | Default            | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `COURSIER_INSTALL_METHOD`  | How to install COURSIER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `COURSIER_VERSION`         | Specific version of coursier to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable   |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                                 | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                                              | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                                          | `none`             |                  |
| `COURSIER_LISTEN_PORT`     | Port for COURSIER to listen on                                                                                                                                           | `none`             |                  |
| `COURSIER_LISTEN_ADDRESS`  | Address for COURSIER to listen on                                                                                                                                        | `none`             |                  |
| `COURSIER_LISTEN_SOCKET`   | Unix socket for COURSIER to listen on                                                                                                                                    | `none`             |                  |
| `COURSIER_DOWNLOAD_URL`    | Override URL for downloading coursier binary or archive artifacts.                                                                                                       | `none`             |                  |
| `COURSIER_RELEASES_URL`    | Override URL for querying coursier available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
