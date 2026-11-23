# Cpanm

**Tier**: `T1` (`_lib/package-managers/cpanm/`) | **Capabilities**: `userland-package`

Bootstrap module for `cpanm` (CPAN Minus - Perl).

## Usage

Ensures the `cpanm` executable is available for installing Perl modules.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CPANM_INSTALL_METHOD` | Installation strategy for cpanm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `CPANM_VERSION`        | Specific version of cpanm to install.                                                                                                                   | `latest`           |                  |
| `CPANM_DOWNLOAD_URL`   | Override URL for downloading cpanm binary or archive artifacts.                                                                                         | `none`             |                  |
| `CPANM_RELEASES_URL`   | Override URL for querying cpanm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
