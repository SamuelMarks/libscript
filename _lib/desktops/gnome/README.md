# GNOME Desktop

Modern desktop environment for Linux

## Usage

```sh
./libscript.sh install gnome
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                            | Default  | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `GNOME_VERSION`        | Specific version of gnome to install.                                                                  | `latest` |                  |
| `GNOME_INSTALL_METHOD` | How to install GNOME. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
