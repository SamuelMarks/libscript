# Minio

High Performance Object Storage. S3 compatible API.

## Usage

```sh
libscript install minio latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MINIO_INSTALL_METHOD` | How to install MINIO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `MINIO_VERSION`        | Specific version of minio to install. Can be a numeric version or an alias.                                                                                           | `latest`           |                  |
| `MINIO_DOWNLOAD_URL`   | Override URL for downloading minio binary or archive artifacts.                                                                                                       | `none`             |                  |
| `MINIO_RELEASES_URL`   | Override URL for querying minio available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
