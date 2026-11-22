# e2fsprogs

Ext2/Ext3/Ext4 filesystem management utilities

## Usage

```sh
./libscript.sh install e2fsprogs
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                | Default  | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `E2FSPROGS_VERSION`        | Specific version of e2fsprogs to install.                                                                  | `latest` |                  |
| `E2FSPROGS_INSTALL_METHOD` | How to install E2FSPROGS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
