# Luarocks

Bootstrap script for [LuaRocks](https://luarocks.org/), the package manager for Lua modules.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                                              | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `LUAROCKS_INSTALL_METHOD` | How to install LUAROCKS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `LUAROCKS_VERSION`        | Specific version of luarocks to install.                                                                                                                                 | `latest`           |                  |
| `LUAROCKS_DOWNLOAD_URL`   | Override URL for downloading luarocks binary or archive artifacts.                                                                                                       | `none`             |                  |
| `LUAROCKS_RELEASES_URL`   | Override URL for querying luarocks available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
