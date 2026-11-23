# YUM (`_lib/package-managers/yum/`)

## Overview

Legacy RHEL/CentOS Yellowdog Updater Modified (yum) RPM package manager wrapper.

- **Tier**: `T1` (`_lib/package-managers/yum/`)
- **Capabilities**: `userland-package`
- **Target OS Whitelist (`manifest.json`)**: `rhel`, `fedora`, `centos`, `rocky`, `almalinux`,
  `linux`

## Usage

```sh
# Bootstrap or invoke the yum package manager adapter
./libscript.sh install yum latest
./_lib/package-managers/yum/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install yum latest
.\_lib\package-managers\yum\cli.cmd test
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/yum/<version>`
  (default `~/.libscript/yum/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `YUM_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `YUM_INSTALL_METHOD` | How to install yum. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `YUM_VERSION`        | Specific version of yum to install.                                                                                                          | `latest` | latest, lts      |
| `YUM_DOWNLOAD_URL`   | Override URL for downloading yum binary or archive artifacts.                                                                                | `none`   |                  |
| `YUM_RELEASES_URL`   | Override URL for querying yum available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
