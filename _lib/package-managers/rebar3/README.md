# Rebar3

Bootstrap module for the `rebar3` package manager.

## Usage

Ensures the `rebar3` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default  | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `REBAR3_INSTALL_METHOD` | How to install REBAR3. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `REBAR3_VERSION`        | Specific version of rebar3 to install.                                                                                                                                 | `latest` |                  |
| `REBAR3_DOWNLOAD_URL`   | Override URL for downloading rebar3 binary or archive artifacts.                                                                                                       | `none`   |                  |
| `REBAR3_RELEASES_URL`   | Override URL for querying rebar3 available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
