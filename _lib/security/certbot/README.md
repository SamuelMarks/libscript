# Certbot (Let's Encrypt ACME Client) (`_lib/security/certbot/`)

## Overview

Electronic Frontier Foundation ACME client for automated Let's Encrypt TLS certificate acquisition
and expiry-gated persistence.

- **Tier**: `T1` (`_lib/security/certbot/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `certbot`, `acme-client`, `letsencrypt`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/certbot/<version>)
./libscript.sh ls-remote certbot
./libscript.sh install certbot latest
./libscript.sh use certbot latest
./libscript.sh which certbot
./_lib/security/certbot/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote certbot
.\libscript.cmd install certbot latest
.\libscript.cmd use certbot latest
.\libscript.cmd which certbot
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/certbot/<version>`
  (default `~/.libscript/certbot/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CERTBOT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                               | Default           | Aliases/Examples |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------- |
| `CERTBOT_VERSION`                  | Specific version of certbot to install. Can be a numeric version or an alias.                                                                             | `latest`          | latest, stable   |
| `CERTBOT_INSTALL_METHOD`           | Installation strategy for Certbot ('system' uses the OS package manager, 'libscript_native' uses isolated version directories).                           | `system`          |                  |
| `CERTBOT_INSTALL_DIR`              | Custom target installation directory for isolated Certbot installations.                                                                                  | `none`            |                  |
| `CERTBOT_DOWNLOAD_URL`             | Override URL for downloading Certbot release archives.                                                                                                    | `none`            |                  |
| `CERTBOT_RELEASES_URL`             | Override URL for querying available upstream Certbot releases.                                                                                            | `none`            |                  |
| `CERT_STORE_DIR`                   | Persistent read-only directory on attached data storage for storing Let's Encrypt certificates across VM instance recreations.                            | `/mnt/data/certs` |                  |
| `LETSENCRYPT_EMAIL`                | Contact email address for Let's Encrypt ACME account registration (if empty, registers with --register-unsafely-without-email).                           | `none`            |                  |
| `LETSENCRYPT_RENEW_BEFORE_SECONDS` | Minimum remaining validity threshold in seconds passed to openssl x509 -checkend before renewing a certificate (default 0 means renew only when expired). | `0`               |                  |
| `LETSENCRYPT_DISABLE_AUTO_RENEW`   | Flag (0 or 1) to disable background OS certbot timers so certificates are only renewed when expired.                                                      | `1`               |                  |
| `LIBSCRIPT_LISTEN_PORT`            | Global fallback TCP port for network-listening components.                                                                                                | `none`            |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`         | Global fallback bind address for network-listening components.                                                                                            | `none`            |                  |
| `LIBSCRIPT_LISTEN_SOCKET`          | Global fallback UNIX domain socket path for listening components.                                                                                         | `none`            |                  |
| `LIBSCRIPT_ALLOW_CERTBOT_SHIM`     | Flag (0 or 1) to allow creating a lightweight certbot CLI shim in isolated dry-run test environments.                                                     | `0`               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
