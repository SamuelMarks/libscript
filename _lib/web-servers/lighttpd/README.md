# Lighttpd

Security, speed, compliance, and very low A-V memory footprint.

## Usage

_Note: libscript manages versions natively for this component._

```sh
libscript install lighttpd latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                              | Default  | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `LIGHTTPD_INSTALL_METHOD`  | How to install LIGHTTPD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `LIGHTTPD_VERSION`         | Specific version of lighttpd to install. Can be a numeric version or an alias.                                                                                           | `latest` | latest, stable   |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                                 | `none`   |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                                              | `none`   |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                                          | `none`   |                  |
| `LIGHTTPD_LISTEN_PORT`     | Port for LIGHTTPD to listen on                                                                                                                                           | `none`   |                  |
| `LIGHTTPD_LISTEN_ADDRESS`  | Address for LIGHTTPD to listen on                                                                                                                                        | `none`   |                  |
| `LIGHTTPD_LISTEN_SOCKET`   | Unix socket for LIGHTTPD to listen on                                                                                                                                    | `none`   |                  |
| `LIGHTTPD_DOWNLOAD_URL`    | Override URL for downloading lighttpd binary or archive artifacts.                                                                                                       | `none`   |                  |
| `LIGHTTPD_RELEASES_URL`    | Override URL for querying lighttpd available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
