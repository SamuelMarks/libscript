# Go Toolchain (`_lib/languages/go/`)

## Overview

An open-source programming language that makes it easy to build simple, reliable, and efficient
software.

- **Tier**: `T1` (`_lib/languages/go/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `compiler`, `go`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/go/<version>)
./libscript.sh ls-remote go
./libscript.sh install go latest
./libscript.sh use go latest
./libscript.sh which go
./_lib/languages/go/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote go
.\libscript.cmd install go latest
.\libscript.cmd use go latest
.\libscript.cmd which go
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/go/<version>`
  (default `~/.libscript/go/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `GO_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                          | Default                           | Aliases/Examples |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------- | ---------------- |
| `GO_VERSION`        | Specific version of go to install. Can be a numeric version or an alias.                                                                             | `latest`                          | latest, stable   |
| `GO_INSTALL_METHOD` | Installation strategy for go: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native`                |                  |
| `GOPROXY`           | Go module proxy URL or 'off' to disable network module fetching.                                                                                     | `https://proxy.golang.org,direct` |                  |
| `GO_VENDOR`         | Flag (0 or 1) indicating Go should build using local vendor directory (-mod=vendor).                                                                 | `0`                               |                  |
| `GO_DOWNLOAD_URL`   | Override URL for downloading go binary or archive artifacts.                                                                                         | `none`                            |                  |
| `GO_RELEASES_URL`   | Override URL for querying go available remote releases.                                                                                              | `none`                            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
