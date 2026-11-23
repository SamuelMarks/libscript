# Pub

**Tier**: `T1` (`_lib/package-managers/pub/`) | **Capabilities**: `userland-package`

Bootstrap module for `pub` (Dart / Flutter package manager).

## Usage

Ensures the `pub` executable (or `dart pub`) is available. This relies on the core Dart toolchain.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PUB_INSTALL_METHOD` | Installation strategy for pub: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PUB_VERSION`        | Specific version of pub to install.                                                                                                                   | `latest`           |                  |
| `PUB_DOWNLOAD_URL`   | Override URL for downloading pub binary or archive artifacts.                                                                                         | `none`             |                  |
| `PUB_RELEASES_URL`   | Override URL for querying pub available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
