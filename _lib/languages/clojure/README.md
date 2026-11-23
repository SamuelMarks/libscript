# Clojure CLI (`_lib/languages/clojure/`)

## Overview

Dynamic, functional Lisp dialect on the JVM with immutable data structures and concurrent
programming primitives.

- **Tier**: `T1` (`_lib/languages/clojure/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `clojure`, `clj`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/clojure/<version>)
./libscript.sh ls-remote clojure
./libscript.sh install clojure latest
./libscript.sh use clojure latest
./libscript.sh which clojure
./_lib/languages/clojure/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote clojure
.\libscript.cmd install clojure latest
.\libscript.cmd use clojure latest
.\libscript.cmd which clojure
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/clojure/<version>`
  (default `~/.libscript/clojure/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CLOJURE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `CLOJURE_INSTALL_METHOD` | How to install clojure. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CLOJURE_VERSION`        | Specific version of clojure to install.                                                                                                          | `latest`           | latest, lts      |
| `CLOJURE_DOWNLOAD_URL`   | Override URL for downloading clojure binary or archive artifacts.                                                                                | `none`             |                  |
| `CLOJURE_RELEASES_URL`   | Override URL for querying clojure available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
