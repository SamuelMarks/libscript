# Ghcup

Bootstrap script for [GHCup](https://www.haskell.org/ghcup/), the main installer for the Haskell
language toolchain (including `cabal` and `stack`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                                 | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GHCUP_BOOTSTRAP_HASKELL_NONINTERACTIVE` | Set to 1 to install ghcup silently without prompts. Default is 1 in this bootstrap.                                                                                   | `none`             |                  |
| `GHCUP_BOOTSTRAP_HASKELL_MINIMAL`        | Set to 1 to install only ghcup (no GHC, cabal, etc. by default). Default is 1.                                                                                        | `none`             |                  |
| `GHCUP_BOOTSTRAP_HASKELL_INSTALL_HLS`    | Set to 1 to also install Haskell Language Server.                                                                                                                     | `none`             |                  |
| `GHCUP_INSTALL_METHOD`                   | How to install GHCUP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `GHCUP_VERSION`                          | Specific version of ghcup to install.                                                                                                                                 | `latest`           |                  |
| `GHCUP_DOWNLOAD_URL`                     | Override URL for downloading ghcup binary or archive artifacts.                                                                                                       | `none`             |                  |
| `GHCUP_RELEASES_URL`                     | Override URL for querying ghcup available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
