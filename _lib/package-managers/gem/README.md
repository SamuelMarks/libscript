# Gem

Bootstrap module for the `gem` package manager.

## Usage

Ensures the `gem` executable is available. This relies on the core language toolchain (e.g., Ruby).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GEM_INSTALL_METHOD` | How to install GEM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `GEM_VERSION`        | Specific version of gem to install.                                                                                                                                 | `latest`           |                  |
| `GEM_DOWNLOAD_URL`   | Override URL for downloading gem binary or archive artifacts.                                                                                                       | `none`             |                  |
| `GEM_RELEASES_URL`   | Override URL for querying gem available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
