<!-- cspell:words msgfmt xgettext msginit msgmerge -->

# gettext

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `gettext` component within
the LibScript ecosystem. GNU `gettext` provides `msgfmt`, `xgettext`, `msginit`, and `msgmerge`
utilities required by `openedx-platform` (`manage.py lms compilemessages`, `compilejsi18n`,
`compile_xblock_translations`, and `compile_plugin_translations`) to compile `.po` translation
catalogs into binary `.mo` files.

## Usage

_Note: libscript manages versions natively for this component._

```sh
libscript install gettext
libscript test gettext
libscript uninstall gettext
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

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
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh` / `setup.cmd`: Entrypoints that resolve the OS and invoke `setup_generic.sh` /
  `setup_generic.cmd`.
- `setup_generic.sh` / `setup_generic.cmd`: Installs `gettext` (`msgfmt`, `xgettext`) via system
  package manager or isolated portable binaries (`gettext-iconv-windows` on Win64) under
  `LIBSCRIPT_HOME`.
- `env.sh` / `env.cmd`: Exports isolated `PATH` entries for `msgfmt` and `xgettext`.
- `test.sh` / `test.cmd`: Verifies `msgfmt --version` and `xgettext --version`.
- `vars.schema.json`: Schema definition for CLI and environment variables.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
