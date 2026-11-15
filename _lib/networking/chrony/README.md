# Chrony NTP

Versatile Network Time Protocol daemon

## Usage

```sh
./libscript.sh install chrony
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                             | Default  | Aliases/Examples |
| ----------------------- | ------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CHRONY_VERSION`        | Specific version of chrony to install.                                                                  | `latest` |                  |
| `CHRONY_INSTALL_METHOD` | How to install CHRONY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
