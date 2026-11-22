# Mosquitto

Eclipse Mosquitto is an open source message broker that implements the MQTT protocol.

## Usage

```sh
libscript install mosquitto latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                               | Default            | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MOSQUITTO_VERSION`        | Specific version of mosquitto to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable   |
| `MOSQUITTO_INSTALL_METHOD` | How to install MOSQUITTO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                                           | `none`             |                  |
| `MOSQUITTO_LISTEN_PORT`    | Port for MOSQUITTO to listen on                                                                                                                                           | `none`             |                  |
| `MOSQUITTO_LISTEN_ADDRESS` | Address for MOSQUITTO to listen on                                                                                                                                        | `none`             |                  |
| `MOSQUITTO_LISTEN_SOCKET`  | Unix socket for MOSQUITTO to listen on                                                                                                                                    | `none`             |                  |
| `MOSQUITTO_DOWNLOAD_URL`   | Override URL for downloading mosquitto binary or archive artifacts.                                                                                                       | `none`             |                  |
| `MOSQUITTO_LISTEN`         | Listen endpoint (address:port or socket) for mosquitto.                                                                                                                   | `none`             |                  |
| `MOSQUITTO_RELEASES_URL`   | Override URL for querying mosquitto available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
