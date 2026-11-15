# Krew

Bootstrap script for [Krew](https://krew.sigs.k8s.io/), the plugin manager for `kubectl`
command-line tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KREW_INSTALL_METHOD` | How to install KREW. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `KREW_ROOT`           | Installation directory for krew and plugins. Defaults to ~/.krew.                                                                                                    | `none`             |                  |
| `KREW_VERSION`        | Specific version of krew to install.                                                                                                                                 | `latest`           |                  |
| `KREW_DOWNLOAD_URL`   | Override URL for downloading krew binary or archive artifacts.                                                                                                       | `none`             |                  |
| `KREW_RELEASES_URL`   | Override URL for querying krew available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
