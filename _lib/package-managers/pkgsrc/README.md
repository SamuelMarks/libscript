# NetBSD pkgsrc (`_lib/package-managers/pkgsrc/`)

## Overview

NetBSD pkgsrc portable cross-platform package management framework (pkgin / bmake).

- **Tier**: `T1` (`_lib/package-managers/pkgsrc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `pkgsrc`, `pkgin`, `bmake`

## Usage

```sh
# Bootstrap or invoke the pkgsrc package manager adapter
./libscript.sh install pkgsrc latest
./_lib/package-managers/pkgsrc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install pkgsrc latest
.\_lib\package-managers\pkgsrc\cli.cmd test
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/pkgsrc/<version>`
  (default `~/.libscript/pkgsrc/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PKGSRC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PKGSRC_INSTALL_METHOD` | How to install pkgsrc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PKGSRC_VERSION`        | Specific version of pkgsrc to install.                                                                                                          | `latest` | latest, lts      |
| `PKGSRC_DOWNLOAD_URL`   | Override URL for downloading pkgsrc binary or archive artifacts.                                                                                | `none`   |                  |
| `PKGSRC_RELEASES_URL`   | Override URL for querying pkgsrc available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
