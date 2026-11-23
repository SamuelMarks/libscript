# FFmpeg (`_lib/utilities/ffmpeg/`)

## Overview

Complete cross-platform solution to record, convert, transcode, and stream audio and video.

- **Tier**: `T1` (`_lib/utilities/ffmpeg/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `ffmpeg`, `ffprobe`, `media-converter`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ffmpeg/<version>)
./libscript.sh ls-remote ffmpeg
./libscript.sh install ffmpeg latest
./libscript.sh use ffmpeg latest
./libscript.sh which ffmpeg
./_lib/utilities/ffmpeg/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ffmpeg
.\libscript.cmd install ffmpeg latest
.\libscript.cmd use ffmpeg latest
.\libscript.cmd which ffmpeg
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ffmpeg/<version>`
  (default `~/.libscript/ffmpeg/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `FFMPEG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `FFMPEG_INSTALL_METHOD` | How to install ffmpeg. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `FFMPEG_VERSION`        | Specific version of ffmpeg to install.                                                                                                          | `latest` | latest, lts      |
| `FFMPEG_DOWNLOAD_URL`   | Override URL for downloading ffmpeg binary or archive artifacts.                                                                                | `none`   |                  |
| `FFMPEG_RELEASES_URL`   | Override URL for querying ffmpeg available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
