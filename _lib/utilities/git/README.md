# Git (`_lib/utilities/git/`)

## Overview

Fast, scalable, distributed revision control system with cryptographic integrity.

- **Tier**: `T1` (`_lib/utilities/git/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `git`, `vcs`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/git/<version>)
./libscript.sh ls-remote git
./libscript.sh install git latest
./libscript.sh use git latest
./libscript.sh which git
./_lib/utilities/git/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote git
.\libscript.cmd install git latest
.\libscript.cmd use git latest
.\libscript.cmd which git
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/git/<version>`
  (default `~/.libscript/git/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `GIT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `GIT_INSTALL_METHOD` | How to install git. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `GIT_VERSION`        | Specific version of git to install.                                                                                                          | `latest` | latest, lts      |
| `GIT_DOWNLOAD_URL`   | Override URL for downloading git binary or archive artifacts.                                                                                | `none`   |                  |
| `GIT_RELEASES_URL`   | Override URL for querying git available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
