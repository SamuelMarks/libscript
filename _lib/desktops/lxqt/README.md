# LXQt Desktop

Lightweight Qt-based desktop environment

## Usage

```sh
./libscript.sh install lxqt
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                           | Default  | Aliases/Examples |
| --------------------- | ----------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LXQT_VERSION`        | Specific version of lxqt to install.                                                                  | `latest` |                  |
| `LXQT_INSTALL_METHOD` | How to install LXQT. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
