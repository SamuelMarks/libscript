# Exim

**Tier**: `T1` (`_lib/utilities/exim/`) | **Capabilities**: `userland-package`, `service-daemon`

Exim mail transfer agent and local SMTP relay daemon.

## Usage

Provides `exim` as a local mail relay for sending platform emails (registration confirmations,
password resets, course announcements).

```sh
./libscript.sh install exim
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                     | Default             | Aliases/Examples |
| ----------------------- | --------------------------------------------------------------- | ------------------- | ---------------- |
| `EXIM_VERSION`          | Specific version of Exim to install (e.g. '4.96', 'latest').    | `latest`            |                  |
| `EXIM_INSTALL_METHOD`   | How to install Exim ('system', 'libscript_native').             | `system`            |                  |
| `EXIM_SMTP_PORT`        | Port for SMTP relay listener.                                   | `25`                |                  |
| `EXIM_RELAY_FROM_HOSTS` | Colon-separated list of hosts/networks permitted to relay mail. | `127.0.0.1 : ::::1` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
