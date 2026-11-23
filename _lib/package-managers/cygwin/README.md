# Cygwin

**Tier**: `T1` (`_lib/package-managers/cygwin/`) | **Capabilities**: `userland-package`

Cygwin POSIX environment for Windows.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CYGWIN_INSTALL_METHOD` | Installation strategy for cygwin: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `CYGWIN_VERSION`        | Specific version of cygwin to install.                                                                                                                   | `latest`           |                  |
| `CYGWIN_DOWNLOAD_URL`   | Override URL for downloading cygwin binary or archive artifacts.                                                                                         | `none`             |                  |
| `CYGWIN_RELEASES_URL`   | Override URL for querying cygwin available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
