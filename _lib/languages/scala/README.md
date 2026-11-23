# Scala (`_lib/languages/scala/`)

## Overview

Expressive statically typed JVM programming language seamlessly combining object-oriented and
functional paradigms.

- **Tier**: `T1` (`_lib/languages/scala/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `scala`, `scalac`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/scala/<version>)
./libscript.sh ls-remote scala
./libscript.sh install scala latest
./libscript.sh use scala latest
./libscript.sh which scala
./_lib/languages/scala/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote scala
.\libscript.cmd install scala latest
.\libscript.cmd use scala latest
.\libscript.cmd which scala
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/scala/<version>`
  (default `~/.libscript/scala/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SCALA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SCALA_INSTALL_METHOD` | How to install scala. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SCALA_VERSION`        | Specific version of scala to install.                                                                                                          | `latest`           | latest, lts      |
| `SCALA_DOWNLOAD_URL`   | Override URL for downloading scala binary or archive artifacts.                                                                                | `none`             |                  |
| `SCALA_RELEASES_URL`   | Override URL for querying scala available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
