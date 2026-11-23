# Just

**Tier**: `T1` (`_lib/toolchains/just/`) | **Capabilities**: `userland-package`

Just a command runner. A handy way to save and run project-specific commands.

## Usage

_Note: libscript manages versions natively for this component._

```sh
libscript install just latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `JUST_INSTALL_METHOD` | Installation strategy for just: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `JUST_VERSION`        | Specific version of just to install. Can be a numeric version or an alias.                                                                             | `latest`           |                  |
| `JUST_DOWNLOAD_URL`   | Override URL for downloading just binary or archive artifacts.                                                                                         | `none`             |                  |
| `JUST_RELEASES_URL`   | Override URL for querying just available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
