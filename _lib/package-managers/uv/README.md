# Uv

Bootstrap module for the `uv` package manager (astral.sh).

## Usage

Installs the `uv` executable via its standalone installer.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                                        | Default  | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `UV_INSTALL_METHOD` | How to install UV. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `UV_VERSION`        | Specific version of uv to install.                                                                                                                                 | `latest` |                  |
| `UV_DOWNLOAD_URL`   | Override URL for downloading uv binary or archive artifacts.                                                                                                       | `none`   |                  |
| `UV_RELEASES_URL`   | Override URL for querying uv available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
