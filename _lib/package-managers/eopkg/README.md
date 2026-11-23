# Eopkg

**Tier**: `T1` (`_lib/package-managers/eopkg/`) | **Capabilities**: `userland-package`

Bootstrap script for `eopkg`, the system package manager for Solus OS.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `EOPKG_INSTALL_METHOD` | Installation strategy for eopkg: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `EOPKG_VERSION`        | Specific version of eopkg to install.                                                                                                                   | `latest`           |                  |
| `EOPKG_DOWNLOAD_URL`   | Override URL for downloading eopkg binary or archive artifacts.                                                                                         | `none`             |                  |
| `EOPKG_RELEASES_URL`   | Override URL for querying eopkg available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
