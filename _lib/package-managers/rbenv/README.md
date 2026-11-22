# Rbenv

Bootstrap module for the `rbenv` package manager.

## Usage

Ensures the `rbenv` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RBENV_INSTALL_METHOD` | How to install RBENV. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `RBENV_VERSION`        | Specific version of rbenv to install.                                                                                                                                 | `latest`           |                  |
| `RBENV_DOWNLOAD_URL`   | Override URL for downloading rbenv binary or archive artifacts.                                                                                                       | `none`             |                  |
| `RBENV_RELEASES_URL`   | Override URL for querying rbenv available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
