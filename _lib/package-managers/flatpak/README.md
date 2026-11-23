# Flatpak

**Tier**: `T1` (`_lib/package-managers/flatpak/`) | **Capabilities**: `userland-package`

Bootstrap module for the `flatpak` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                               | Default            | Aliases/Examples |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FLATPAK_INSTALL_METHOD` | Installation strategy for flatpak: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `FLATPAK_VERSION`        | Specific version of flatpak to install.                                                                                                                   | `latest`           |                  |
| `FLATPAK_DOWNLOAD_URL`   | Override URL for downloading flatpak binary or archive artifacts.                                                                                         | `none`             |                  |
| `FLATPAK_RELEASES_URL`   | Override URL for querying flatpak available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
