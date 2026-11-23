# Cabal

**Tier**: `T1` (`_lib/package-managers/cabal/`) | **Capabilities**: `userland-package`

Bootstrap module for `cabal` (Haskell package manager).

## Usage

Ensures the `cabal` executable is available. This relies on `ghcup`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CABAL_INSTALL_METHOD` | Installation strategy for cabal: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `CABAL_VERSION`        | Specific version of cabal to install.                                                                                                                   | `latest`           |                  |
| `CABAL_DOWNLOAD_URL`   | Override URL for downloading cabal binary or archive artifacts.                                                                                         | `none`             |                  |
| `CABAL_RELEASES_URL`   | Override URL for querying cabal available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
