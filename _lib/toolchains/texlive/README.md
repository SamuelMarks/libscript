# texlive

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `texlive` component (part
of `_toolchains`) within the LibScript ecosystem. Reproducible scholarly LaTeX typesetting toolchain
providing pdflatex and bibtex.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **TeX Live Typesetting
Toolchain**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install texlive
libscript uninstall texlive
```

**Start / Stop (if configured as a background service):**

```sh
libscript start texlive
libscript stop texlive
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker texlive
```

_Note: On Unix environments, you can also use `./cli.sh install texlive`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

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
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
