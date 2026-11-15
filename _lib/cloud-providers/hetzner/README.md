# Hetzner

Hetzner component for LibScript systems.

## Usage

```sh
./libscript.sh install hetzner
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                              | Default  | Aliases/Examples |
| ------------------------ | -------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `HETZNER_VERSION`        | Specific version of Hetzner tooling to install.                                                          | `latest` |                  |
| `HETZNER_INSTALL_METHOD` | How to install HETZNER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |
| `HETZNER_IP`             | Override target IPv4/IPv6 address for Hetzner node SSH and rsync operations.                             | ``       |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
