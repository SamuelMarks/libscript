# Ruby Runtime (`_lib/languages/ruby/`)

## Overview

A dynamic, open source programming language with a focus on simplicity and productivity.

- **Tier**: `T1` (`_lib/languages/ruby/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `ruby`, `gem`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ruby/<version>)
./libscript.sh ls-remote ruby
./libscript.sh install ruby latest
./libscript.sh use ruby latest
./libscript.sh which ruby
./_lib/languages/ruby/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ruby
.\libscript.cmd install ruby latest
.\libscript.cmd use ruby latest
.\libscript.cmd which ruby
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ruby/<version>`
  (default `~/.libscript/ruby/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `RUBY_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `RUBY_VERSION`        | Specific version of ruby to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `RUBY_INSTALL_METHOD` | Installation strategy for ruby: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `GEM_OFFLINE`         | Flag (0 or 1) directing gem to install packages only from local archives.                                                                              | `0`                |                  |
| `BUNDLE_LOCAL`        | Flag ('true' or 'false') instructing Bundler to run in local offline mode without remote queries.                                                      | `false`            |                  |
| `RUBY_DOWNLOAD_URL`   | Override URL for downloading ruby binary or archive artifacts.                                                                                         | `none`             |                  |
| `RUBY_RELEASES_URL`   | Override URL for querying ruby available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
