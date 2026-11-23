# NATS

**Tier**: `T1` (`_lib/message-brokers/nats/`) | **Capabilities**: `userland-package`,
`service-daemon`

High-Performance open source messaging system for cloud native applications, IoT messaging, and
microservices architectures.

## Usage

```sh
libscript install nats latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                            | Default            | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `NATS_VERSION`             | Specific version of nats to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `NATS_INSTALL_METHOD`      | Installation strategy for nats: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                        | `none`             |                  |
| `NATS_LISTEN_PORT`         | Port for NATS to listen on                                                                                                                             | `none`             |                  |
| `NATS_LISTEN_ADDRESS`      | Address for NATS to listen on                                                                                                                          | `none`             |                  |
| `NATS_LISTEN_SOCKET`       | Unix socket for NATS to listen on                                                                                                                      | `none`             |                  |
| `NATS_DOWNLOAD_URL`        | Override URL for downloading nats binary or archive artifacts.                                                                                         | `none`             |                  |
| `NATS_LISTEN`              | Listen endpoint (address:port or socket) for nats.                                                                                                     | `none`             |                  |
| `NATS_RELEASES_URL`        | Override URL for querying nats available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
