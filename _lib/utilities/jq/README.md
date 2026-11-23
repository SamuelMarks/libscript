# jq (`_lib/utilities/jq/`)

## Overview

Lightweight command-line JSON processor with native Windows (MSVC) and MS-DOS (dos32) builds via
SamuelMarks/jq-windows.

- **Tier**: `T1` (`_lib/utilities/jq/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `jq`, `jq-windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/jq/<version>)
./libscript.sh ls-remote jq
./libscript.sh install jq latest
./libscript.sh use jq latest
./libscript.sh which jq
./_lib/utilities/jq/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote jq
.\libscript.cmd install jq latest
.\libscript.cmd use jq latest
.\libscript.cmd which jq
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/jq/<version>`
  (default `~/.libscript/jq/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `JQ_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                                                                                         | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `JQ_INSTALL_METHOD` | How to install jq. 'libscript_native' installs isolated prebuilt binaries (dos32 on MS-DOS, PE on Windows, static/prebuilt on POSIX), 'system' uses the OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `JQ_VERSION`        | Specific version of jq to install (e.g., 1.8.2 on Windows/MS-DOS or latest).                                                                                                                                        | `latest`           | latest, lts      |
| `JQ_DOWNLOAD_URL`   | Override URL for downloading jq binary or archive artifacts.                                                                                                                                                        | `none`             |                  |
| `JQ_RELEASES_URL`   | Override URL for querying jq available remote releases.                                                                                                                                                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
