# Go

Bootstrap module for the `go` package manager (enables `go install`).

## Usage

Ensures the `go` executable is available by pulling in the core `go` toolchain.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GO_PM_INSTALL_METHOD` | How to install GO_PM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `GO_PM_VERSION`        | Specific version of go to install.                                                                                                                                    | `latest`           |                  |
| `GO_PM_DOWNLOAD_URL`   | Override URL for downloading go-pm binary or archive artifacts.                                                                                                       | `none`             |                  |
| `GO_PM_RELEASES_URL`   | Override URL for querying go-pm available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
