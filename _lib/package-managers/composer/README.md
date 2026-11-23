# Composer

**Tier**: `T1` (`_lib/package-managers/composer/`) | **Capabilities**: `userland-package`

Bootstrap module for the `composer` package manager.

## Usage

Ensures the `composer` executable is available by delegating to the `_toolchain/composer` module.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                                | Default            | Aliases/Examples |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `COMPOSER_INSTALL_METHOD` | Installation strategy for composer: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `COMPOSER_VERSION`        | Specific version of composer to install.                                                                                                                   | `latest`           |                  |
| `COMPOSER_DOWNLOAD_URL`   | Override URL for downloading composer binary or archive artifacts.                                                                                         | `none`             |                  |
| `COMPOSER_RELEASES_URL`   | Override URL for querying composer available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
