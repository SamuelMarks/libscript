# yq (`_lib/utilities/yq/`)

## Overview

Portable command-line YAML, JSON, XML, CSV, and TOML processor using jq-like expression syntax.

- **Tier**: `T1` (`_lib/utilities/yq/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `yq`, `yaml-processor`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/yq/<version>)
./libscript.sh ls-remote yq
./libscript.sh install yq latest
./libscript.sh use yq latest
./libscript.sh which yq
./_lib/utilities/yq/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote yq
.\libscript.cmd install yq latest
.\libscript.cmd use yq latest
.\libscript.cmd which yq
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/yq/<version>`
  (default `~/.libscript/yq/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `YQ_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `YQ_INSTALL_METHOD` | How to install yq. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `YQ_VERSION`        | Specific version of yq to install.                                                                                                          | `latest`           | latest, lts      |
| `YQ_DOWNLOAD_URL`   | Override URL for downloading yq binary or archive artifacts.                                                                                | `none`             |                  |
| `YQ_RELEASES_URL`   | Override URL for querying yq available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
