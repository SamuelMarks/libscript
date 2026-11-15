# Zypper

Bootstrap module for the `zypper` package manager.

## Usage

This module ensures `zypper` is available and updated. Since `zypper` is natively integrated into
its corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ZYPPER_INSTALL_METHOD` | How to install ZYPPER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `ZYPPER_VERSION`        | Specific version of zypper to install.                                                                                                                                 | `latest`           |                  |
| `ZYPPER_DOWNLOAD_URL`   | Override URL for downloading zypper binary or archive artifacts.                                                                                                       | `none`             |                  |
| `ZYPPER_RELEASES_URL`   | Override URL for querying zypper available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
