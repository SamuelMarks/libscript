# NVIDIA Graphics Driver

Proprietary NVIDIA display driver and libraries

## Usage

```sh
./libscript.sh install nvidia
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                    | Default  | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `NVIDIA_VERSION`        | Specific version of nvidia driver to install.                                                                  | `latest` |                  |
| `NVIDIA_INSTALL_METHOD` | How to install NVIDIA driver. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
