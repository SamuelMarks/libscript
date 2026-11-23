# Apache Groovy (`_lib/languages/groovy/`)

## Overview

Multi-faceted dynamic and optionally typed programming language for the Java platform.

- **Tier**: `T1` (`_lib/languages/groovy/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `groovy`, `groovyc`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/groovy/<version>)
./libscript.sh ls-remote groovy
./libscript.sh install groovy latest
./libscript.sh use groovy latest
./libscript.sh which groovy
./_lib/languages/groovy/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote groovy
.\libscript.cmd install groovy latest
.\libscript.cmd use groovy latest
.\libscript.cmd which groovy
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/groovy/<version>`
  (default `~/.libscript/groovy/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `GROOVY_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GROOVY_INSTALL_METHOD` | How to install groovy. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GROOVY_VERSION`        | Specific version of groovy to install.                                                                                                          | `latest`           | latest, lts      |
| `GROOVY_DOWNLOAD_URL`   | Override URL for downloading groovy binary or archive artifacts.                                                                                | `none`             |                  |
| `GROOVY_RELEASES_URL`   | Override URL for querying groovy available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
