# Fail2ban (`_lib/security/fail2ban/`)

## Overview

Log-scanning intrusion prevention daemon that bans malicious hosts exhibiting brute-force patterns.

- **Tier**: `T1` (`_lib/security/fail2ban/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `fail2ban`, `ips`, `security`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/fail2ban/<version>)
./libscript.sh ls-remote fail2ban
./libscript.sh install fail2ban latest
./libscript.sh use fail2ban latest
./libscript.sh which fail2ban
./_lib/security/fail2ban/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote fail2ban
.\libscript.cmd install fail2ban latest
.\libscript.cmd use fail2ban latest
.\libscript.cmd which fail2ban
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/fail2ban/<version>`
  (default `~/.libscript/fail2ban/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FAIL2BAN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `FAIL2BAN_INSTALL_METHOD` | How to install fail2ban. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `FAIL2BAN_VERSION`        | Specific version of fail2ban to install.                                                                                                          | `latest` | latest, lts      |
| `FAIL2BAN_DOWNLOAD_URL`   | Override URL for downloading fail2ban binary or archive artifacts.                                                                                | `none`   |                  |
| `FAIL2BAN_RELEASES_URL`   | Override URL for querying fail2ban available remote releases.                                                                                     | `none`   |                  |
| `FAIL2BAN_LISTEN_PORT`    | TCP port on which the fail2ban service listens.                                                                                                   | `8080`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
