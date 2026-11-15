# GitLab

GitLab Community Edition (CE) is a self-hosted Git management software based on Ruby on Rails.

**Note:** GitLab is a very large application stack. This module attempts to install it via the
official libscript_native package manager (Omnibus). If you encounter issues, consider using Docker
instead.

## Usage

```sh
libscript install gitlab latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                            | Default            | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GITLAB_VERSION`           | Specific version of gitlab to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable   |
| `GITLAB_INSTALL_METHOD`    | How to install GITLAB. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                                        | `none`             |                  |
| `GITLAB_LISTEN_PORT`       | Port for GITLAB to listen on                                                                                                                                           | `none`             |                  |
| `GITLAB_LISTEN_ADDRESS`    | Address for GITLAB to listen on                                                                                                                                        | `none`             |                  |
| `GITLAB_LISTEN_SOCKET`     | Unix socket for GITLAB to listen on                                                                                                                                    | `none`             |                  |
| `GITLAB_DOWNLOAD_URL`      | Override URL for downloading gitlab binary or archive artifacts.                                                                                                       | `none`             |                  |
| `GITLAB_LISTEN`            | Listen endpoint (address:port or socket) for gitlab.                                                                                                                   | `none`             |                  |
| `GITLAB_RELEASES_URL`      | Override URL for querying gitlab available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
