# Pnpm

**Tier**: `T1` (`_lib/package-managers/pnpm/`) | **Capabilities**: `userland-package`

Bootstrap module for the `pnpm` package manager.

## Usage

Ensures the `pnpm` executable is available by pulling in Node.js/npm and running
`npm install -g pnpm`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default  | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `PNPM_INSTALL_METHOD` | Installation strategy for pnpm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `PNPM_VERSION`        | Specific version of pnpm to install.                                                                                                                   | `latest` |                  |
| `PNPM_DOWNLOAD_URL`   | Override URL for downloading pnpm binary or archive artifacts.                                                                                         | `none`   |                  |
| `PNPM_RELEASES_URL`   | Override URL for querying pnpm available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
