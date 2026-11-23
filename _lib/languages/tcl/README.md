# Tcl/Tk (`_lib/languages/tcl/`)

## Overview

Tool Command Language (tclsh) dynamic scripting interpreter and embeddable runtime.

- **Tier**: `T1` (`_lib/languages/tcl/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `tcl`, `tclsh`, `tk`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/tcl/<version>)
./libscript.sh ls-remote tcl
./libscript.sh install tcl latest
./libscript.sh use tcl latest
./libscript.sh which tcl
./_lib/languages/tcl/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote tcl
.\libscript.cmd install tcl latest
.\libscript.cmd use tcl latest
.\libscript.cmd which tcl
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tcl/<version>`
  (default `~/.libscript/tcl/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TCL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `TCL_INSTALL_METHOD` | How to install tcl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `TCL_VERSION`        | Specific version of tcl to install.                                                                                                          | `latest` | latest, lts      |
| `TCL_DOWNLOAD_URL`   | Override URL for downloading tcl binary or archive artifacts.                                                                                | `none`   |                  |
| `TCL_RELEASES_URL`   | Override URL for querying tcl available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
