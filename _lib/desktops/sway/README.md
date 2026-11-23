# Sway Compositor

**Tier**: `T2` (`_lib/desktops/sway/`) | **Capabilities**: `sysroot-package`

i3-compatible tiling Wayland compositor

## Usage

```sh
./libscript.sh install sway
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                           | Default  | Aliases/Examples |
| --------------------- | ----------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `SWAY_VERSION`        | Specific version of sway to install.                                                                  | `latest` |                  |
| `SWAY_INSTALL_METHOD` | How to install SWAY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
