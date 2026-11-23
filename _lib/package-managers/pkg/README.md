# Pkg

**Tier**: `T1` (`_lib/package-managers/pkg/`) | **Capabilities**: `userland-package`

Bootstrap module for the FreeBSD `pkg` package manager.

## Usage

Ensures the FreeBSD `pkg` executable is available by running `pkg bootstrap`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PKG_INSTALL_METHOD` | Installation strategy for pkg: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PKG_VERSION`        | Specific version of pkg to install.                                                                                                                   | `latest`           |                  |
| `PKG_DOWNLOAD_URL`   | Override URL for downloading pkg binary or archive artifacts.                                                                                         | `none`             |                  |
| `PKG_RELEASES_URL`   | Override URL for querying pkg available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
