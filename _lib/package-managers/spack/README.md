# Spack

**Tier**: `T1` (`_lib/package-managers/spack/`) | **Capabilities**: `userland-package`

Bootstrap script for [Spack](https://spack.io/), a flexible package manager that supports multiple
versions, configurations, platforms, and compilers.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SPACK_INSTALL_METHOD` | Installation strategy for spack: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `SPACK_VERSION`        | Specific version of spack to install.                                                                                                                   | `latest`           |                  |
| `SPACK_DOWNLOAD_URL`   | Override URL for downloading spack binary or archive artifacts.                                                                                         | `none`             |                  |
| `SPACK_RELEASES_URL`   | Override URL for querying spack available remote releases.                                                                                              | `none`             |                  |
| `SPACK_SCRIPT`         | Filesystem path to the Spack Python entrypoint script (bin/spack) wrapped by LibScript shims.                                                           | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
