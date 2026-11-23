# Secrets Management, PKI, IAM & Intrusion Prevention (`_lib/security/`)

## Overview

**Tier Scope**: `T1`

Secrets vaults (`openbao`, `vault`), internal PKI/ACME (`step-ca`, `certbot`), identity providers
(`keycloak`), WireGuard VPN tooling, and active defense daemons (`crowdsec`, `fail2ban`).

Each subdirectory in `_lib/security/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/security/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh certbot --help
./libscript.sh install certbot latest
./_lib/security/certbot/cli.sh test
```

```cmd
.\libscript.cmd certbot --help
.\libscript.cmd install certbot latest
.\_lib\security\certbot\cli.cmd test
```

## Components (8)

<!-- BEGIN_COMPONENTS -->

- [`certbot`](./certbot/README.md) (`T1` — `userland-package`): Electronic Frontier Foundation ACME
  client for automated Let's Encrypt TLS certificate acquisition and expiry-gated persistence.
- [`crowdsec`](./crowdsec/README.md) (`T1` — `userland-package`, `service-daemon`): Collaborative,
  open-source intrusion prevention and behavioral threat intelligence security engine.
- [`fail2ban`](./fail2ban/README.md) (`T1` — `userland-package`): Log-scanning intrusion prevention
  daemon that bans malicious hosts exhibiting brute-force patterns.
- [`keycloak`](./keycloak/README.md) (`T1` — `userland-package`, `service-daemon`): Open-source
  Identity and Access Management server supporting OpenID Connect, OAuth 2.0, and SAML 2.0.
- [`openbao`](./openbao/README.md) (`T1` — `userland-package`, `service-daemon`): An open-source
  tool for managing secrets and protecting sensitive data.
- [`step-ca`](./step-ca/README.md) (`T1` — `userland-package`, `service-daemon`): Private online
  X.509 and SSH certificate authority server supporting automated ACME certificate issuance.
- [`vault`](./vault/README.md) (`T1` — `userland-package`, `service-daemon`): Identity-based secrets
  management, dynamic credentials, and encryption-as-a-service server.
- [`wireguard`](./wireguard/README.md) (`T1` — `userland-package`, `service-daemon`): Fast, modern,
  cryptographically opinionated VPN tunnel configuration utilities (wg and wg-quick).

<!-- END_COMPONENTS -->
