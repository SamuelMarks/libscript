# Bun

**Tier**: `T1` (`_lib/package-managers/bun-pm/`) | **Capabilities**: `userland-package`

Bootstrap script for [Bun](https://bun.sh), a fast all-in-one JavaScript runtime, bundler, test
runner, and package manager.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BUN_PM_INSTALL_METHOD` | Installation strategy for bun-pm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `BUN_PM_INSTALL`        | Path to the directory where Bun should be installed. Defaults to ~/.bun.                                                                                 | `none`             |                  |
| `BUN_PM_VERSION`        | Specific version of bun to install.                                                                                                                      | `latest`           |                  |
| `BUN_PM_DOWNLOAD_URL`   | Override URL for downloading bun-pm binary or archive artifacts.                                                                                         | `none`             |                  |
| `BUN_PM_RELEASES_URL`   | Override URL for querying bun-pm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
