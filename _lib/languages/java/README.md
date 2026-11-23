# Java Toolchain (`_lib/languages/java/`)

## Overview

Java Development Kit (JDK) and runtime environment.

- **Tier**: `T1` (`_lib/languages/java/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `java`, `jre`, `jdk`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/java/<version>)
./libscript.sh ls-remote java
./libscript.sh install java latest
./libscript.sh use java latest
./libscript.sh which java
./_lib/languages/java/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote java
.\libscript.cmd install java latest
.\libscript.cmd use java latest
.\libscript.cmd which java
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/java/<version>`
  (default `~/.libscript/java/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `JAVA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `JAVA_INSTALL_METHOD` | Installation strategy for java: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `JAVA_VERSION`        | Version of Java Toolchain to install                                                                                                                   | `latest`           |                  |
| `JAVA_DOWNLOAD_URL`   | Override URL for downloading java binary or archive artifacts.                                                                                         | `none`             |                  |
| `JAVA_HOME`           | Filesystem directory or path configuration for java (JAVA_HOME).                                                                                       | `none`             |                  |
| `JAVA_RELEASES_URL`   | Override URL for querying java available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
