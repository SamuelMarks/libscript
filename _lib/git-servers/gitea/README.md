# Gitea

**Tier**: `T1` (`_lib/git-servers/gitea/`) | **Capabilities**: `userland-package`, `service-daemon`

Git with a cup of tea! A painless self-hosted Git service.

## Usage

```sh
libscript install gitea 1.22.3
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                             | Default            | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GITEA_VERSION`            | Specific version of gitea to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `GITEA_INSTALL_METHOD`     | Installation strategy for gitea: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                             | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                         | `none`             |                  |
| `GITEA_LISTEN_PORT`        | Port for GITEA to listen on                                                                                                                             | `none`             |                  |
| `GITEA_LISTEN_ADDRESS`     | Address for GITEA to listen on                                                                                                                          | `none`             |                  |
| `GITEA_LISTEN_SOCKET`      | Unix socket for GITEA to listen on                                                                                                                      | `none`             |                  |
| `GITEA_DOWNLOAD_URL`       | Override URL for downloading gitea binary or archive artifacts.                                                                                         | `none`             |                  |
| `GITEA_LISTEN`             | Listen endpoint (address:port or socket) for gitea.                                                                                                     | `none`             |                  |
| `GITEA_RELEASES_URL`       | Override URL for querying gitea available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
