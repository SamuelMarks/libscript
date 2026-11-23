# Graphviz (`_lib/utilities/graphviz/`)

## Overview

Open-source graph visualization software and DOT layout CLI tools (dot, neato, fdp).

- **Tier**: `T1` (`_lib/utilities/graphviz/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `graphviz`, `dot`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/graphviz/<version>)
./libscript.sh ls-remote graphviz
./libscript.sh install graphviz latest
./libscript.sh use graphviz latest
./libscript.sh which graphviz
./_lib/utilities/graphviz/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote graphviz
.\libscript.cmd install graphviz latest
.\libscript.cmd use graphviz latest
.\libscript.cmd which graphviz
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/graphviz/<version>`
  (default `~/.libscript/graphviz/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GRAPHVIZ_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `GRAPHVIZ_INSTALL_METHOD` | How to install graphviz. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `GRAPHVIZ_VERSION`        | Specific version of graphviz to install.                                                                                                          | `latest` | latest, lts      |
| `GRAPHVIZ_DOWNLOAD_URL`   | Override URL for downloading graphviz binary or archive artifacts.                                                                                | `none`   |                  |
| `GRAPHVIZ_RELEASES_URL`   | Override URL for querying graphviz available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
