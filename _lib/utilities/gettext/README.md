# GNU gettext (`_lib/utilities/gettext/`)

## Overview

Internationalization and localization utilities (msgfmt, xgettext, msginit, msgmerge) used by Open
edX translation compilation.

- **Tier**: `T1` (`_lib/utilities/gettext/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `gettext`, `msgfmt`, `xgettext`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/gettext/<version>)
./libscript.sh ls-remote gettext
./libscript.sh install gettext latest
./libscript.sh use gettext latest
./libscript.sh which gettext
./_lib/utilities/gettext/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote gettext
.\libscript.cmd install gettext latest
.\libscript.cmd use gettext latest
.\libscript.cmd which gettext
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/gettext/<version>`
  (default `~/.libscript/gettext/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GETTEXT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                     | Default            | Aliases/Examples |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GETTEXT_INSTALL_METHOD` | How to install gettext. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, or 'from-source' compiles from source. | `libscript_native` |                  |
| `GETTEXT_VERSION`        | Specific version of gettext to install.                                                                                                         | `latest`           |                  |
| `GETTEXT_INSTALL_DIR`    | Target directory for isolated gettext installation.                                                                                             | `none`             |                  |
| `GETTEXT_OFFLINE`        | Flag (true/false or 1/0) indicating air-gapped offline installation mode for gettext.                                                           | `false`            |                  |
| `GETTEXT_DOWNLOAD_URL`   | Override URL for downloading gettext binary or archive artifacts.                                                                               | `none`             |                  |
| `GETTEXT_RELEASES_URL`   | Override URL for querying gettext available remote releases.                                                                                    | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
