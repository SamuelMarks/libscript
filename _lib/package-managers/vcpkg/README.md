# Vcpkg

**Tier**: `T1` (`_lib/package-managers/vcpkg/`) | **Capabilities**: `userland-package`

Bootstrap module for the `vcpkg` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `VCPKG_INSTALL_METHOD` | Installation strategy for vcpkg: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `VCPKG_VERSION`        | Specific version of vcpkg to install.                                                                                                                   | `latest`           |                  |
| `VCPKG_DOWNLOAD_URL`   | Override URL for downloading vcpkg binary or archive artifacts.                                                                                         | `none`             |                  |
| `VCPKG_RELEASES_URL`   | Override URL for querying vcpkg available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
