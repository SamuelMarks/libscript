# R

Bootstrap module for the `R` package manager.

## Usage

Ensures the `R` executable is available. This relies on the core language toolchain appropriate for
the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable           | Description                                                                                                                                                       | Default  | Aliases/Examples |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `R_INSTALL_METHOD` | How to install R. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `R_VERSION`        | Specific version of R to install.                                                                                                                                 | `latest` |                  |
| `R_DOWNLOAD_URL`   | Override URL for downloading r binary or archive artifacts.                                                                                                       | `none`   |                  |
| `R_RELEASES_URL`   | Override URL for querying r available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
