# Maven Wrapper (`_lib/package-managers/maven-wrapper/`)

## Overview

Apache Maven Wrapper (mvnw) standalone distribution manager for reproducible JVM project builds.

- **Tier**: `T1` (`_lib/package-managers/maven-wrapper/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `maven-wrapper`, `mvnw`

## Usage

```sh
# Bootstrap or invoke the maven-wrapper package manager adapter
./libscript.sh install maven-wrapper latest
./_lib/package-managers/maven-wrapper/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install maven-wrapper latest
.\_lib\package-managers\maven-wrapper\cli.cmd test
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/maven-wrapper/<version>` (default `~/.libscript/maven-wrapper/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `MAVEN_WRAPPER_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                            | Default            | Aliases/Examples |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `MAVEN_WRAPPER_INSTALL_METHOD` | How to install maven-wrapper. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `MAVEN_WRAPPER_VERSION`        | Specific version of maven-wrapper to install.                                                                                                          | `latest`           | latest, lts      |
| `MAVEN_WRAPPER_DOWNLOAD_URL`   | Override URL for downloading maven-wrapper binary or archive artifacts.                                                                                | `none`             |                  |
| `MAVEN_WRAPPER_RELEASES_URL`   | Override URL for querying maven-wrapper available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
