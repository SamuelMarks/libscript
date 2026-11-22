# fail2ban

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `fail2ban` component (part
of `_security`) within the LibScript ecosystem. Log-scanning intrusion prevention daemon that bans
malicious hosts exhibiting brute-force patterns.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Fail2ban**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install fail2ban
libscript uninstall fail2ban
```

**Start / Stop (if configured as a background service):**

```sh
libscript start fail2ban
libscript stop fail2ban
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker fail2ban
```

_Note: On Unix environments, you can also use `./cli.sh install fail2ban`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

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

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
