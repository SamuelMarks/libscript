# Nimble

**Tier**: `T1` (`_lib/package-managers/nimble/`) | **Capabilities**: `userland-package`

Bootstrap script for [Nimble](https://github.com/nim-lang/nimble), the package manager for the Nim
programming language. Typically installed via `choosenim`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                                                              | Default            | Aliases/Examples |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NIMBLE_INSTALL_METHOD`           | Installation strategy for nimble: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `NIMBLE_CHOOSENIM_DIR`            | Installation directory for choosenim. Defaults to ~/.choosenim.                                                                                          | `none`             |                  |
| `NIMBLE_CHOOSENIM_CHOOSE_VERSION` | Specific Nim version to install initially.                                                                                                               | `none`             |                  |
| `NIMBLE_VERSION`                  | Specific version of nimble to install.                                                                                                                   | `latest`           |                  |
| `NIMBLE_DOWNLOAD_URL`             | Override URL for downloading nimble binary or archive artifacts.                                                                                         | `none`             |                  |
| `NIMBLE_RELEASES_URL`             | Override URL for querying nimble available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
