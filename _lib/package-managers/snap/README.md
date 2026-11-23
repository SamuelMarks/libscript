# Snap

**Tier**: `T1` (`_lib/package-managers/snap/`) | **Capabilities**: `userland-package`

Bootstrap module for the `snap` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `SNAP_INSTALL_METHOD` | Installation strategy for snap: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `SNAP_VERSION`        | Specific version of snap to install.                                                                                                                   | `latest`           |                  |
| `SNAP_DOWNLOAD_URL`   | Override URL for downloading snap binary or archive artifacts.                                                                                         | `none`             |                  |
| `SNAP_RELEASES_URL`   | Override URL for querying snap available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
