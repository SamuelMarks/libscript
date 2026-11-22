# KDE Plasma 6

Feature-rich desktop workspace by KDE

## Usage

```sh
./libscript.sh install kde-plasma-6
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                   | Default  | Aliases/Examples |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `KDE_PLASMA_6_VERSION`        | Specific version of kde-plasma-6 to install.                                                                  | `latest` |                  |
| `KDE_PLASMA_6_INSTALL_METHOD` | How to install KDE_PLASMA_6. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
