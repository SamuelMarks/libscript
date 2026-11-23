# aria2

**Tier**: `T1` (`_lib/utilities/aria2/`) | **Capabilities**: `userland-package`

Provides lightweight utility wrappers for the `aria2` multi-protocol download utility, heavily
utilized by the package management layer for parallelized fetching.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default  | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `ARIA2_INSTALL_METHOD` | Installation strategy for aria2: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `ARIA2_VERSION`        | Specific version of aria2 to install.                                                                                                                   | `latest` |                  |
| `ARIA2_DOWNLOAD_URL`   | Override URL for downloading aria2 binary or archive artifacts.                                                                                         | `none`   |                  |
| `ARIA2_RELEASES_URL`   | Override URL for querying aria2 available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
