# Yarn

**Tier**: `T1` (`_lib/package-managers/yarn/`) | **Capabilities**: `userland-package`

Bootstrap module for the `yarn` package manager.

## Usage

Ensures the `yarn` executable is available by pulling in Node.js/npm and running
`npm install -g yarn`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default  | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `YARN_INSTALL_METHOD` | Installation strategy for yarn: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `YARN_VERSION`        | Specific version of yarn to install.                                                                                                                   | `latest` |                  |
| `YARN_DOWNLOAD_URL`   | Override URL for downloading yarn binary or archive artifacts.                                                                                         | `none`   |                  |
| `YARN_RELEASES_URL`   | Override URL for querying yarn available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
