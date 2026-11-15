# Direct Rendering Manager

Low-level userspace interface to kernel DRM

## Usage

```sh
./libscript.sh install libdrm
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                             | Default  | Aliases/Examples |
| ----------------------- | ------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `LIBDRM_VERSION`        | Specific version of libdrm to install.                                                                  | `latest` |                  |
| `LIBDRM_INSTALL_METHOD` | How to install LIBDRM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
