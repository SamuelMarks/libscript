# OpenTofu (`_lib/iac/tofu/`)

## Overview

OpenTofu (tofu) Linux Foundation open-source Infrastructure-as-Code CLI drop-in replacement for
Terraform.

- **Tier**: `T1` (`_lib/iac/tofu/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `tofu`, `opentofu`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/tofu/<version>)
./libscript.sh ls-remote tofu
./libscript.sh install tofu latest
./libscript.sh use tofu latest
./libscript.sh which tofu
./_lib/iac/tofu/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote tofu
.\libscript.cmd install tofu latest
.\libscript.cmd use tofu latest
.\libscript.cmd which tofu
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tofu/<version>`
  (default `~/.libscript/tofu/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TOFU_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TOFU_INSTALL_METHOD` | How to install tofu. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TOFU_VERSION`        | Specific version of tofu to install.                                                                                                          | `latest`           | latest, stable   |
| `TOFU_DOWNLOAD_URL`   | Override URL for downloading tofu binary or archive artifacts.                                                                                | `none`             |                  |
| `TOFU_RELEASES_URL`   | Override URL for querying tofu available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
