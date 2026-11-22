# XFCE Desktop

Fast and lightweight desktop environment

## Usage

```sh
./libscript.sh install xfce4
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                            | Default  | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `XFCE4_VERSION`        | Specific version of xfce4 to install.                                                                  | `latest` |                  |
| `XFCE4_INSTALL_METHOD` | How to install XFCE4. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
