# google-cloud-sdk

Provides bootstrap definitions and wrappers for installing the Google Cloud SDK (`gcloud`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                                                                                      | Default            | Aliases/Examples |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GOOGLE_CLOUD_SDK_INSTALL_METHOD` | How to install GOOGLE_CLOUD_SDK. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `GOOGLE_CLOUD_SDK_VERSION`        | Version of Google Cloud SDK to install                                                                                                                                           | `latest`           |                  |
| `GOOGLE_CLOUD_SDK_DOWNLOAD_URL`   | Override URL for downloading google-cloud-sdk binary or archive artifacts.                                                                                                       | `none`             |                  |
| `GOOGLE_CLOUD_SDK_RELEASES_URL`   | Override URL for querying google-cloud-sdk available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
