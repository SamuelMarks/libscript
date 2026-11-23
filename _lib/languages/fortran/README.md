# GNU Fortran (`_lib/languages/fortran/`)

## Overview

GNU Fortran (gfortran) scientific and numerical array programming compiler.

- **Tier**: `T1` (`_lib/languages/fortran/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `fortran`, `gfortran`, `f95`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/fortran/<version>)
./libscript.sh ls-remote fortran
./libscript.sh install fortran latest
./libscript.sh use fortran latest
./libscript.sh which fortran
./_lib/languages/fortran/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote fortran
.\libscript.cmd install fortran latest
.\libscript.cmd use fortran latest
.\libscript.cmd which fortran
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/fortran/<version>`
  (default `~/.libscript/fortran/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FORTRAN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `FORTRAN_INSTALL_METHOD` | How to install fortran. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `FORTRAN_VERSION`        | Specific version of fortran to install.                                                                                                          | `latest` | latest, lts      |
| `FORTRAN_DOWNLOAD_URL`   | Override URL for downloading fortran binary or archive artifacts.                                                                                | `none`   |                  |
| `FORTRAN_RELEASES_URL`   | Override URL for querying fortran available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
