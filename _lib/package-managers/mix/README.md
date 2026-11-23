# Mix

**Tier**: `T1` (`_lib/package-managers/mix/`) | **Capabilities**: `userland-package`

Bootstrap module for `mix` (Elixir package manager and build tool).

## Usage

Ensures the `mix` executable is available by leveraging the core Elixir toolchain.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MIX_INSTALL_METHOD` | Installation strategy for mix: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `MIX_VERSION`        | Specific version of mix to install.                                                                                                                   | `latest`           |                  |
| `MIX_DOWNLOAD_URL`   | Override URL for downloading mix binary or archive artifacts.                                                                                         | `none`             |                  |
| `MIX_RELEASES_URL`   | Override URL for querying mix available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
