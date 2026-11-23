# tree (`_lib/utilities/tree/`)

## Overview

Recursive depth-indented directory listing utility supporting colorized text, JSON, and XML output.

- **Tier**: `T1` (`_lib/utilities/tree/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `tree`, `directory-lister`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/tree/<version>)
./libscript.sh ls-remote tree
./libscript.sh install tree latest
./libscript.sh use tree latest
./libscript.sh which tree
./_lib/utilities/tree/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote tree
.\libscript.cmd install tree latest
.\libscript.cmd use tree latest
.\libscript.cmd which tree
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tree/<version>`
  (default `~/.libscript/tree/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TREE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `TREE_INSTALL_METHOD` | How to install tree. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `TREE_VERSION`        | Specific version of tree to install.                                                                                                          | `latest` | latest, lts      |
| `TREE_DOWNLOAD_URL`   | Override URL for downloading tree binary or archive artifacts.                                                                                | `none`   |                  |
| `TREE_RELEASES_URL`   | Override URL for querying tree available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
