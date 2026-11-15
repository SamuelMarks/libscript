# imagemagick

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `imagemagick` component
(part of `_utilities`) within the LibScript ecosystem. Raster and vector digital image creation,
editing, composition, and conversion CLI suite (magick).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **ImageMagick**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install imagemagick
libscript uninstall imagemagick
```

**Start / Stop (if configured as a background service):**

```sh
libscript start imagemagick
libscript stop imagemagick
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker imagemagick
```

_Note: On Unix environments, you can also use `./cli.sh install imagemagick`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default  | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `IMAGEMAGICK_INSTALL_METHOD` | How to install imagemagick. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `IMAGEMAGICK_VERSION`        | Specific version of imagemagick to install.                                                                                                          | `latest` | latest, lts      |
| `IMAGEMAGICK_DOWNLOAD_URL`   | Override URL for downloading imagemagick binary or archive artifacts.                                                                                | `none`   |                  |
| `IMAGEMAGICK_RELEASES_URL`   | Override URL for querying imagemagick available remote releases.                                                                                     | `none`   |                  |

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
