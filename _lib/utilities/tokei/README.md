# Tokei Source Code Auditor (`_lib/utilities/tokei/`)

## Overview

Fast, deterministic polyglot source line (SLOC) and file statistics auditor.

- **Tier**: `T1` (`_lib/utilities/tokei/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/tokei/<version>)
./libscript.sh ls-remote tokei
./libscript.sh install tokei latest
./libscript.sh use tokei latest
./libscript.sh which tokei
./_lib/utilities/tokei/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote tokei
.\libscript.cmd install tokei latest
.\libscript.cmd use tokei latest
.\libscript.cmd which tokei
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tokei/<version>`
  (default `~/.libscript/tokei/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TOKEI_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TOKEI_INSTALL_METHOD` | How to install tokei. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TOKEI_VERSION`        | Specific version of tokei to install.                                                                                                          | `latest`           | latest, lts      |
| `TOKEI_DOWNLOAD_URL`   | Override URL for downloading tokei binary or archive artifacts.                                                                                | `none`             |                  |
| `TOKEI_RELEASES_URL`   | Override URL for querying tokei available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
