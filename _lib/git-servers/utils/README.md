# Git Servers Shared Utilities (`_lib/git-servers/utils/`)

## Overview

Shared functions and utilities for Git Server components (Gitea, GitLab).

- **Tier**: `T1` (`_lib/git-servers/utils/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `git-servers-utils`

## Usage

```sh
# Install and manage the utils service daemon
./libscript.sh install utils latest
./libscript.sh start utils
./libscript.sh status utils
./libscript.sh logs utils
./libscript.sh stop utils
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install utils latest
.\libscript.cmd start utils
.\libscript.cmd status utils
.\libscript.cmd stop utils
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/utils/<version>`
  (default `~/.libscript/utils/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `UTILS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                 | Default | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------- | ------- | ---------------- |
| `1`                    | repository                                                                  | `none`  |                  |
| `2`                    | target directory                                                            | `none`  |                  |
| `3`                    | branch                                                                      | `none`  |                  |
| `UTILS_DOWNLOAD_URL`   | Override URL for downloading utils binary or archive artifacts.             | `none`  |                  |
| `UTILS_INSTALL_METHOD` | Installation method for utils (libscript_native, system, or from-source).   | `none`  |                  |
| `UTILS_RELEASES_URL`   | Override URL for querying utils available remote releases.                  | `none`  |                  |
| `UTILS_VERSION`        | Specific version of utils to install (e.g., latest, lts, or exact version). | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
