# Erlang/OTP (`_lib/languages/erlang/`)

## Overview

Concurrent, fault-tolerant functional programming language and BEAM runtime environment.

- **Tier**: `T1` (`_lib/languages/erlang/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `erlang`, `erl`, `erlc`, `beam`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/erlang/<version>)
./libscript.sh ls-remote erlang
./libscript.sh install erlang latest
./libscript.sh use erlang latest
./libscript.sh which erlang
./_lib/languages/erlang/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote erlang
.\libscript.cmd install erlang latest
.\libscript.cmd use erlang latest
.\libscript.cmd which erlang
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/erlang/<version>`
  (default `~/.libscript/erlang/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ERLANG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `ERLANG_INSTALL_METHOD` | How to install erlang. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `ERLANG_VERSION`        | Specific version of erlang to install.                                                                                                          | `latest` | latest, lts      |
| `ERLANG_DOWNLOAD_URL`   | Override URL for downloading erlang binary or archive artifacts.                                                                                | `none`   |                  |
| `ERLANG_RELEASES_URL`   | Override URL for querying erlang available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
