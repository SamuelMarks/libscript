# Lynx (`_lib/utilities/lynx/`)

## Overview

Text-mode web browser and HTML-to-plaintext renderer used by Open edX bulk email and annotations.

- **Tier**: `T1` (`_lib/utilities/lynx/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/lynx/<version>)
./libscript.sh ls-remote lynx
./libscript.sh install lynx latest
./libscript.sh use lynx latest
./libscript.sh which lynx
./_lib/utilities/lynx/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote lynx
.\libscript.cmd install lynx latest
.\libscript.cmd use lynx latest
.\libscript.cmd which lynx
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/lynx/<version>`
  (default `~/.libscript/lynx/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `LYNX_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                  | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LYNX_INSTALL_METHOD` | How to install lynx. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, or 'from-source' compiles from source. | `libscript_native` |                  |
| `LYNX_VERSION`        | Specific version of lynx to install.                                                                                                         | `latest`           |                  |
| `LYNX_INSTALL_DIR`    | Target directory for isolated lynx installation.                                                                                             | `none`             |                  |
| `LYNX_OFFLINE`        | Flag (true/false or 1/0) indicating air-gapped offline installation mode for lynx.                                                           | `false`            |                  |
| `LYNX_DOWNLOAD_URL`   | Override URL for downloading lynx binary or archive artifacts.                                                                               | `none`             |                  |
| `LYNX_RELEASES_URL`   | Override URL for querying lynx available remote releases.                                                                                    | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
