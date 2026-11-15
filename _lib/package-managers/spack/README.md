# Spack

Bootstrap script for [Spack](https://spack.io/), a flexible package manager that supports multiple
versions, configurations, platforms, and compilers.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SPACK_INSTALL_METHOD` | How to install SPACK. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `SPACK_VERSION`        | Specific version of spack to install.                                                                                                                                 | `latest`           |                  |
| `SPACK_DOWNLOAD_URL`   | Override URL for downloading spack binary or archive artifacts.                                                                                                       | `none`             |                  |
| `SPACK_RELEASES_URL`   | Override URL for querying spack available remote releases.                                                                                                            | `none`             |                  |
| `SPACK_SCRIPT`         | Configuration variable SPACK_SCRIPT for spack.                                                                                                                        | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
