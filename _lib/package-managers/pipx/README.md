# Pipx

Bootstrap module for the `pipx` package manager.

## Usage

Ensures the `pipx` executable is available for installing Python CLI tools in isolated environments.
This module relies on the core Python toolchain and `pip`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default  | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PIPX_INSTALL_METHOD` | How to install PIPX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `PIPX_VERSION`        | Specific version of pipx to install.                                                                                                                                 | `latest` |                  |
| `PIPX_DOWNLOAD_URL`   | Override URL for downloading pipx binary or archive artifacts.                                                                                                       | `none`   |                  |
| `PIPX_RELEASES_URL`   | Override URL for querying pipx available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
