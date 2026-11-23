# GNU Autoconf (`_lib/toolchains/autoconf/`)

## Overview

Extensible M4 macro package producing portable POSIX configure scripts.

- **Tier**: `T1` (`_lib/toolchains/autoconf/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/autoconf/<version>)
./libscript.sh ls-remote autoconf
./libscript.sh install autoconf latest
./libscript.sh use autoconf latest
./libscript.sh which autoconf
./_lib/toolchains/autoconf/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote autoconf
.\libscript.cmd install autoconf latest
.\libscript.cmd use autoconf latest
.\libscript.cmd which autoconf
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/autoconf/<version>`
  (default `~/.libscript/autoconf/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `AUTOCONF_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `AUTOCONF_INSTALL_METHOD` | How to install autoconf. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `AUTOCONF_VERSION`        | Specific version of autoconf to install.                                                                                                          | `latest` | latest, 2.72     |
| `AUTOCONF_DOWNLOAD_URL`   | Override URL for downloading autoconf binary or archive artifacts.                                                                                | `none`   |                  |
| `AUTOCONF_RELEASES_URL`   | Override URL for querying autoconf available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
