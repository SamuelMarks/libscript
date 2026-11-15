# Composer

Bootstrap module for the `composer` package manager.

## Usage

Ensures the `composer` executable is available by delegating to the `_toolchain/composer` module.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                                              | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `COMPOSER_INSTALL_METHOD` | How to install COMPOSER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `COMPOSER_VERSION`        | Specific version of composer to install.                                                                                                                                 | `latest`           |                  |
| `COMPOSER_DOWNLOAD_URL`   | Override URL for downloading composer binary or archive artifacts.                                                                                                       | `none`             |                  |
| `COMPOSER_RELEASES_URL`   | Override URL for querying composer available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
