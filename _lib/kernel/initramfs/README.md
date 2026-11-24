# Initramfs

**Tier**: `T2` (`_lib/kernel/initramfs/`) | **Capabilities**: `sysroot-package`, `kernel-image`

Initramfs component for LibScript systems.

## Usage

```sh
./libscript.sh install initramfs
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                | Default  | Aliases/Examples |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `INITRAMFS_VERSION`            | Specific version of initramfs to install.                                                                  | `latest` |                  |
| `INITRAMFS_INSTALL_METHOD`     | How to install INITRAMFS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |
| `LIBSCRIPT_INITRAMFS_COMPRESS` | Compression algorithm used when packing cpio newc initramfs archives.                                      | `zstd`   |                  |
| `LIBSCRIPT_LUKS_CMDLINE`       | Optional cryptdevice/root kernel command-line override injected into early-userspace init.                 | ``       |                  |
| `LIBSCRIPT_INIT_SMOKE_ROOT`    | Optional staging root path used when running early-userspace init smoke tests.                             | ``       |                  |
| `LIBSCRIPT_INIT_SMOKE_EXIT`    | Flag (0 or 1) causing synthesized /init to exit cleanly after LUKS2/mount verification in smoke tests.     | `0`      |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
