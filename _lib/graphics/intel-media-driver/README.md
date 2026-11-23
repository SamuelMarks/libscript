# Intel Media Driver

**Tier**: `T2` (`_lib/graphics/intel-media-driver/`) | **Capabilities**: `sysroot-package`,
`sysroot-library`

VAAPI hardware accelerated video driver for Intel

## Usage

```sh
./libscript.sh install intel-media-driver
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                            | Description                                                         | Default  | Aliases/Examples |
| ----------------------------------- | ------------------------------------------------------------------- | -------- | ---------------- |
| `INTEL_MEDIA_DRIVER_VERSION`        | Specific version of intel-media-driver to install.                  | `latest` |                  |
| `INTEL_MEDIA_DRIVER_INSTALL_METHOD` | How to install INTEL_MEDIA_DRIVER ('libscript_native' or 'system'). | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
