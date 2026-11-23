# Mise

**Tier**: `T1` (`_lib/package-managers/mise/`) | **Capabilities**: `userland-package`

Bootstrap module for the `mise` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `MISE_INSTALL_METHOD` | Installation strategy for mise: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `MISE_VERSION`        | Installation strategy for mise: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `latest`           |                  |
| `MISE_DOWNLOAD_URL`   | Installation strategy for mise: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `none`             |                  |
| `MISE_RELEASES_URL`   | Installation strategy for mise: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
