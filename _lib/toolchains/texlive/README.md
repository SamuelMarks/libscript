# TeX Live Typesetting Toolchain (`_lib/toolchains/texlive/`)

## Overview

Reproducible scholarly LaTeX typesetting toolchain providing pdflatex and bibtex.

- **Tier**: `T1` (`_lib/toolchains/texlive/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `texlive`, `pdflatex`, `bibtex`, `latex`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/texlive/<version>)
./libscript.sh ls-remote texlive
./libscript.sh install texlive latest
./libscript.sh use texlive latest
./libscript.sh which texlive
./_lib/toolchains/texlive/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote texlive
.\libscript.cmd install texlive latest
.\libscript.cmd use texlive latest
.\libscript.cmd which texlive
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/texlive/<version>`
  (default `~/.libscript/texlive/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `TEXLIVE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default                                                              | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------- | ---------------- |
| `TEXLIVE_INSTALL_METHOD` | How to install texlive. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`                                                   |                  |
| `TEXLIVE_VERSION`        | Specific version of texlive to install.                                                                                                          | `2025`                                                               | latest, lts      |
| `TEXLIVE_DOWNLOAD_URL`   | Override URL for downloading texlive binary or archive artifacts.                                                                                | `none`                                                               |                  |
| `TEXLIVE_RELEASES_URL`   | Override URL for querying texlive available remote releases.                                                                                     | `none`                                                               |                  |
| `TEXLIVE_SCHEME`         | TeX Live base scheme installed into the isolated version prefix.                                                                                 | `scheme-basic`                                                       |                  |
| `TEXLIVE_EXTRA_PACKAGES` | Space-separated CTAN packages installed via tlmgr to prevent missing styles or Type-3 bitmap PK fonts.                                           | `acmart pgfplots pgf booktabs microtype hyperref cm-super libertine` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
