# Fnm

**Tier**: `T1` (`_lib/package-managers/fnm/`) | **Capabilities**: `userland-package`

Bootstrap script for [fnm](https://github.com/Schniz/fnm), a fast and simple Node.js version
manager.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `FNM_INSTALL_METHOD` | Installation strategy for fnm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `FNM_DIR`            | Installation directory for fnm.                                                                                                                       | `none`             |                  |
| `FNM_VERSION`        | Specific version of fnm to install.                                                                                                                   | `latest`           |                  |
| `FNM_DOWNLOAD_URL`   | Override URL for downloading fnm binary or archive artifacts.                                                                                         | `none`             |                  |
| `FNM_RELEASES_URL`   | Override URL for querying fnm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
