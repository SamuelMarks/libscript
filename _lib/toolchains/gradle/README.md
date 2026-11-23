# Gradle

**Tier**: `T1` (`_lib/toolchains/gradle/`) | **Capabilities**: `userland-package`

Bootstrap module for `gradle` (Java / JVM build automation system).

## Usage

_Note: libscript manages versions natively for this component._

Ensures the `gradle` executable is available. Relies on the core Java toolchain and commonly uses
`sdkman` to manage versions on UNIX-like environments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default  | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `GRADLE_INSTALL_METHOD` | Installation strategy for gradle: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `GRADLE_VERSION`        | Specific version of gradle to install. Can be a numeric version or an alias.                                                                             | `latest` |                  |
| `GRADLE_DOWNLOAD_URL`   | Override URL for downloading gradle binary or archive artifacts.                                                                                         | `none`   |                  |
| `GRADLE_RELEASES_URL`   | Override URL for querying gradle available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
