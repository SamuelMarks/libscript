# Cpanm

Bootstrap module for `cpanm` (CPAN Minus - Perl).

## Usage

Ensures the `cpanm` executable is available for installing Perl modules.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CPANM_INSTALL_METHOD` | How to install CPANM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `CPANM_VERSION`        | Specific version of cpanm to install.                                                                                                                                 | `latest`           |                  |
| `CPANM_DOWNLOAD_URL`   | Override URL for downloading cpanm binary or archive artifacts.                                                                                                       | `none`             |                  |
| `CPANM_RELEASES_URL`   | Override URL for querying cpanm available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
