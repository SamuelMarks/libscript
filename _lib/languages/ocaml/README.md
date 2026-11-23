# OCaml (`_lib/languages/ocaml/`)

## Overview

Industrial-strength functional, imperative, and object-oriented programming language with static
type inference.

- **Tier**: `T1` (`_lib/languages/ocaml/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `ocaml`, `ocamlc`, `ocamlopt`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ocaml/<version>)
./libscript.sh ls-remote ocaml
./libscript.sh install ocaml latest
./libscript.sh use ocaml latest
./libscript.sh which ocaml
./_lib/languages/ocaml/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ocaml
.\libscript.cmd install ocaml latest
.\libscript.cmd use ocaml latest
.\libscript.cmd which ocaml
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ocaml/<version>`
  (default `~/.libscript/ocaml/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `OCAML_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `OCAML_INSTALL_METHOD` | How to install ocaml. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OCAML_VERSION`        | Specific version of ocaml to install.                                                                                                          | `latest` | latest, lts      |
| `OCAML_DOWNLOAD_URL`   | Override URL for downloading ocaml binary or archive artifacts.                                                                                | `none`   |                  |
| `OCAML_RELEASES_URL`   | Override URL for querying ocaml available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
