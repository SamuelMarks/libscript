# Perl (`_lib/languages/perl/`)

## Overview

Highly capable, feature-rich general-purpose scripting and text-processing programming language.

- **Tier**: `T1` (`_lib/languages/perl/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/perl/<version>)
./libscript.sh ls-remote perl
./libscript.sh install perl latest
./libscript.sh use perl latest
./libscript.sh which perl
./_lib/languages/perl/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote perl
.\libscript.cmd install perl latest
.\libscript.cmd use perl latest
.\libscript.cmd which perl
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/perl/<version>`
  (default `~/.libscript/perl/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PERL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PERL_INSTALL_METHOD` | How to install perl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PERL_VERSION`        | Specific version of perl to install.                                                                                                          | `latest` | latest, lts      |
| `PERL_DOWNLOAD_URL`   | Override URL for downloading perl binary or archive artifacts.                                                                                | `none`   |                  |
| `PERL_RELEASES_URL`   | Override URL for querying perl available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
