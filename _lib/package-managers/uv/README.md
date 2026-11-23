# Uv

**Tier**: `T1` (`_lib/package-managers/uv/`) | **Capabilities**: `userland-package`

Bootstrap module for the `uv` package manager (astral.sh).

## Usage

Installs the `uv` executable via its standalone installer.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                          | Default  | Aliases/Examples |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `UV_INSTALL_METHOD` | Installation strategy for uv: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `UV_VERSION`        | Specific version of uv to install.                                                                                                                   | `latest` |                  |
| `UV_DOWNLOAD_URL`   | Override URL for downloading uv binary or archive artifacts.                                                                                         | `none`   |                  |
| `UV_RELEASES_URL`   | Override URL for querying uv available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
