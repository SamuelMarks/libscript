# Maven

Bootstrap module for the `maven` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default  | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `MAVEN_INSTALL_METHOD` | How to install MAVEN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `MAVEN_VERSION`        | Specific version of maven to install. Can be a numeric version or an alias.                                                                                           | `latest` |                  |
| `MAVEN_DOWNLOAD_URL`   | Override URL for downloading maven binary or archive artifacts.                                                                                                       | `none`   |                  |
| `MAVEN_RELEASES_URL`   | Override URL for querying maven available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
