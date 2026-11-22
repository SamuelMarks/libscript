# Kafka

Open-source distributed event streaming platform used by thousands of companies for high-performance
data pipelines, streaming analytics, data integration, and mission-critical applications.

## Requirements

Requires Java (JRE or JDK) 11+.

## Usage

```sh
libscript install java latest
libscript install kafka latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                           | Default            | Aliases/Examples |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KAFKA_VERSION`            | Specific version of kafka to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable   |
| `KAFKA_INSTALL_METHOD`     | How to install KAFKA. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`    | Global port to listen on                                                                                                                                              | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on                                                                                                                                           | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`  | Global unix socket to listen on                                                                                                                                       | `none`             |                  |
| `KAFKA_LISTEN_PORT`        | Port for KAFKA to listen on                                                                                                                                           | `none`             |                  |
| `KAFKA_LISTEN_ADDRESS`     | Address for KAFKA to listen on                                                                                                                                        | `none`             |                  |
| `KAFKA_LISTEN_SOCKET`      | Unix socket for KAFKA to listen on                                                                                                                                    | `none`             |                  |
| `KAFKA_DOWNLOAD_URL`       | Override URL for downloading kafka binary or archive artifacts.                                                                                                       | `none`             |                  |
| `KAFKA_ENABLED`            | Flag (0 or 1) indicating whether kafka is enabled in the execution plan.                                                                                              | `none`             |                  |
| `KAFKA_RELEASES_URL`       | Override URL for querying kafka available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
