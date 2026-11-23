# Node.js Runtime (`_lib/languages/nodejs/`)

## Overview

JavaScript runtime built on Chrome's V8 JavaScript engine.

- **Tier**: `T1` (`_lib/languages/nodejs/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `javascript`, `nodejs`, `npm`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/nodejs/<version>)
./libscript.sh ls-remote nodejs
./libscript.sh install nodejs latest
./libscript.sh use nodejs latest
./libscript.sh which nodejs
./_lib/languages/nodejs/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote nodejs
.\libscript.cmd install nodejs latest
.\libscript.cmd use nodejs latest
.\libscript.cmd which nodejs
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/nodejs/<version>`
  (default `~/.libscript/nodejs/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `NODEJS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                           | Default            | Aliases/Examples                       |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------------------------------------- |
| `NODEJS_VERSION`                | Version of Node.js demanded. Can be an alias or a specific numeric version number                                                     | `lts`              | lts, latest, lts, latest, v22.13.1, 20 |
| `NODEJS_CUSTOM_EXECUTABLE_PATH` | Path to existing host node.exe executable. If provided, bypasses installing a new Node.js runtime.                                    | `none`             |                                        |
| `NODEJS_USE_SYSTEM`             | Reuse existing host Node.js runtime located at NODEJS_CUSTOM_EXECUTABLE_PATH rather than installing bundled Node.js.                  | `none`             |                                        |
| `NODEJS_INSTALL_METHOD`         | How to install NODEJS. 'libscript_native' uses isolated version dirs natively handled by libscript, 'system' uses OS package manager. | `libscript_native` |                                        |
| `NPM_CACHE`                     | Directory of pre-populated offline npm cache tarballs and metadata.                                                                   | `none`             |                                        |
| `YARN_OFFLINE_MIRROR`           | Directory of offline tarball mirror for yarn package installation.                                                                    | `none`             |                                        |
| `NODEJS_DOWNLOAD_URL`           | Override URL for downloading nodejs binary or archive artifacts.                                                                      | `none`             |                                        |
| `NODEJS_RELEASES_URL`           | Override URL for querying nodejs available remote releases.                                                                           | `none`             |                                        |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
