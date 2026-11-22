# lynx

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `lynx` component within
the LibScript ecosystem. `lynx` is a classic text-mode web browser and HTML-to-plaintext converter
required by `openedx-platform` (`openedx/core/lib/html_to_text.py`) to render bulk HTML course
emails and annotations into plaintext.

## Usage

_Note: libscript manages versions natively for this component._

```sh
libscript install lynx
libscript test lynx
libscript uninstall lynx
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

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

## Architecture

- `setup.sh` / `setup.cmd`: Entrypoints that resolve the OS and invoke `setup_generic.sh` /
  `setup_generic.cmd`.
- `setup_generic.sh` / `setup_generic.cmd`: Installs `lynx` via system package manager or isolated
  portable binary/filter under `LIBSCRIPT_HOME`.
- `env.sh` / `env.cmd`: Exports isolated `PATH` entries for `lynx`.
- `test.sh` / `test.cmd`: Verifies `lynx -version` and `lynx -stdin -dump -nolist` HTML-to-text
  conversion.
- `vars.schema.json`: Schema definition for CLI and environment variables.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
