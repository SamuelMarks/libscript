# Yay

Bootstrap module for the `yay` package manager.

## Usage

Ensures the `yay` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `YAY_INSTALL_METHOD` | How to install YAY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `YAY_VERSION`        | Specific version of yay to install.                                                                                                                                 | `latest`           |                  |
| `YAY_DOWNLOAD_URL`   | Override URL for downloading yay binary or archive artifacts.                                                                                                       | `none`             |                  |
| `YAY_RELEASES_URL`   | Override URL for querying yay available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
