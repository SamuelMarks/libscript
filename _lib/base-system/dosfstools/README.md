# Dosfstools

**Tier**: `T2` (`_lib/base-system/dosfstools/`) | **Capabilities**: `sysroot-package`

FAT and VFAT filesystem utilities

## Usage

```sh
./libscript.sh install dosfstools
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                 | Default  | Aliases/Examples |
| --------------------------- | ----------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `DOSFSTOOLS_VERSION`        | Specific version of dosfstools to install.                                                                  | `latest` |                  |
| `DOSFSTOOLS_INSTALL_METHOD` | How to install DOSFSTOOLS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
