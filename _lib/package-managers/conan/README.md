# Conan

Bootstrap module for `conan` (C/C++ package manager).

## Usage

Ensures the `conan` executable is available. This relies on Python (`pip` or `pipx`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CONAN_INSTALL_METHOD` | How to install CONAN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `CONAN_VERSION`        | Specific version of conan to install.                                                                                                                                 | `latest`           |                  |
| `CONAN_DOWNLOAD_URL`   | Override URL for downloading conan binary or archive artifacts.                                                                                                       | `none`             |                  |
| `CONAN_RELEASES_URL`   | Override URL for querying conan available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
