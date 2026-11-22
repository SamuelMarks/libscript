# Dnf

Bootstrap module for the `dnf` package manager.

## Usage

This module ensures `dnf` is available and updated. Since `dnf` is natively integrated into its
corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DNF_INSTALL_METHOD` | How to install DNF. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `DNF_VERSION`        | Specific version of dnf to install.                                                                                                                                 | `latest`           |                  |
| `DNF_DOWNLOAD_URL`   | Override URL for downloading dnf binary or archive artifacts.                                                                                                       | `none`             |                  |
| `DNF_RELEASES_URL`   | Override URL for querying dnf available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
