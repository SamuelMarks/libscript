# Certbot (Let's Encrypt ACME Client)

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `certbot` component within
the `_lib/security` category of LibScript. Certbot is the Electronic Frontier Foundation's ACME
client for acquiring and managing Let's Encrypt TLS certificates with persistent read-only storage
on `/mnt/data/certs` and strict expiry-gated renewal.

## Usage

You can manage the lifecycle of `certbot` using the global `libscript` orchestrator or the local
component CLI.

**Unix (Linux/macOS/BSD):**

```sh
./libscript.sh install certbot
./_lib/security/certbot/cli.sh install

./libscript.sh status certbot
./_lib/security/certbot/cli.sh status

./libscript.sh uninstall certbot
./_lib/security/certbot/cli.sh uninstall
```

**Windows:**

```cmd
libscript.cmd install certbot
_lib\security\certbot\cli.cmd install

libscript.cmd status certbot
_lib\security\certbot\cli.cmd status

libscript.cmd uninstall certbot
_lib\security\certbot\cli.cmd uninstall
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

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

## Architecture

- `cli.sh` / `cli.cmd`: Primary CLI router delegating to `engine/common/component_core.*`.
- `setup.sh` / `setup.cmd`: Main installation entrypoint delegating to `engine/common/setup_base.*`.
- `setup_generic.sh` / `setup_generic.cmd`: Installs Certbot via `libscript_depends 'certbot'` and
  disables automatic background renewal timers when `LETSENCRYPT_DISABLE_AUTO_RENEW=1`.
- `env.sh` / `env.cmd`: Exports `CERT_STORE_DIR` and `LETSENCRYPT_RENEW_BEFORE_SECONDS`.
- `test.sh` / `test.cmd`: Smoke tests verifying Certbot CLI routing and availability.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
