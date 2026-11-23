# Smallstep step-ca (`_lib/security/step-ca/`)

## Overview

Private online X.509 and SSH certificate authority server supporting automated ACME certificate
issuance.

- **Tier**: `T1` (`_lib/security/step-ca/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `step-ca`, `certificate-authority`, `acme`

## Usage

```sh
# Install and manage the step-ca service daemon
./libscript.sh install step-ca latest
./libscript.sh start step-ca
./libscript.sh status step-ca
./libscript.sh logs step-ca
./libscript.sh stop step-ca
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install step-ca latest
.\libscript.cmd start step-ca
.\libscript.cmd status step-ca
.\libscript.cmd stop step-ca
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/step-ca/<version>`
  (default `~/.libscript/step-ca/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `STEP_CA_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `STEP_CA_INSTALL_METHOD` | How to install step-ca. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `STEP_CA_VERSION`        | Specific version of step-ca to install.                                                                                                          | `latest`           | latest, lts      |
| `STEP_CA_DOWNLOAD_URL`   | Override URL for downloading step-ca binary or archive artifacts.                                                                                | `none`             |                  |
| `STEP_CA_RELEASES_URL`   | Override URL for querying step-ca available remote releases.                                                                                     | `none`             |                  |
| `STEP_CA_LISTEN_PORT`    | TCP port on which the step-ca service listens.                                                                                                   | `9000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
