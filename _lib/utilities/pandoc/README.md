# Pandoc (`_lib/utilities/pandoc/`)

## Overview

Universal markup document converter supporting Markdown, LaTeX, HTML, DOCX, EPUB, and PDF.

- **Tier**: `T1` (`_lib/utilities/pandoc/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `pandoc`, `document-converter`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/pandoc/<version>)
./libscript.sh ls-remote pandoc
./libscript.sh install pandoc latest
./libscript.sh use pandoc latest
./libscript.sh which pandoc
./_lib/utilities/pandoc/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote pandoc
.\libscript.cmd install pandoc latest
.\libscript.cmd use pandoc latest
.\libscript.cmd which pandoc
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/pandoc/<version>`
  (default `~/.libscript/pandoc/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PANDOC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PANDOC_INSTALL_METHOD` | How to install pandoc. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PANDOC_VERSION`        | Specific version of pandoc to install.                                                                                                          | `latest`           | latest, lts      |
| `PANDOC_DOWNLOAD_URL`   | Override URL for downloading pandoc binary or archive artifacts.                                                                                | `none`             |                  |
| `PANDOC_RELEASES_URL`   | Override URL for querying pandoc available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
