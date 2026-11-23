# OpenSSL (`_lib/utilities/openssl/`)

## Overview

Full-featured commercial-grade TLS/SSL cryptography library and openssl command-line toolkit.

- **Tier**: `T1` (`_lib/utilities/openssl/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `openssl`, `tls-toolkit`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/openssl/<version>)
./libscript.sh ls-remote openssl
./libscript.sh install openssl latest
./libscript.sh use openssl latest
./libscript.sh which openssl
./_lib/utilities/openssl/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote openssl
.\libscript.cmd install openssl latest
.\libscript.cmd use openssl latest
.\libscript.cmd which openssl
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/openssl/<version>`
  (default `~/.libscript/openssl/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `OPENSSL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `OPENSSL_INSTALL_METHOD` | How to install openssl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OPENSSL_VERSION`        | Specific version of openssl to install.                                                                                                          | `latest` | latest, lts      |
| `OPENSSL_DOWNLOAD_URL`   | Override URL for downloading openssl binary or archive artifacts.                                                                                | `none`   |                  |
| `OPENSSL_RELEASES_URL`   | Override URL for querying openssl available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
