# nssm

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `nssm` (Non-Sucking
Service Manager) component within the LibScript ecosystem. `nssm` wraps native Windows executables
(`waitress-serve.exe`, `celery.exe`, `caddy.exe`, `meilisearch.exe`) as resilient Windows Services
with automatic restart, working directory binding (`AppDirectory`), environment variable injection
(`AppEnvironmentExtra`), and stdout/stderr log rotation (`AppStdout`, `AppStderr`).

## Usage

_Note: libscript manages versions natively for this component._

```sh
libscript install nssm
libscript test nssm
libscript uninstall nssm
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                        | Default            | Aliases/Examples |
| --------------------- | ---------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NSSM_INSTALL_METHOD` | How to install nssm ('libscript_native' or 'system').                              | `libscript_native` |                  |
| `NSSM_VERSION`        | Specific version of nssm to install.                                               | `2.24`             |                  |
| `NSSM_INSTALL_DIR`    | Target directory for isolated nssm installation.                                   | `none`             |                  |
| `NSSM_OFFLINE`        | Flag (true/false or 1/0) indicating air-gapped offline installation mode for nssm. | `false`            |                  |
| `NSSM_DOWNLOAD_URL`   | Override URL for downloading nssm release zip archive.                             | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh` / `setup.cmd`: Entrypoints that resolve the OS and invoke `setup_generic.sh` /
  `setup_generic.cmd`.
- `setup_generic.sh` / `setup_generic.cmd`: Installs `nssm.exe` (Win64) under `LIBSCRIPT_HOME`.
- `env.sh` / `env.cmd`: Exports isolated `PATH` entries for `nssm`.
- `test.sh` / `test.cmd`: Verifies `nssm` availability.
- `vars.schema.json`: Schema definition for CLI and environment variables.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
