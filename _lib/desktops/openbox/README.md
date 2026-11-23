# Openbox

**Tier**: `T2` (`_lib/desktops/openbox/`) | **Capabilities**: `sysroot-package`

## Purpose & Overview

Provides the lightweight Openbox floating X11 window manager, tint2 panel configuration, and default
session autostart orchestration for Linux From Scratch appliances.

## Usage

```sh
# Configure Openbox inside the target rootfs
./_lib/desktops/openbox/setup.sh install /path/to/rootfs

# Check installation status
./_lib/desktops/openbox/setup.sh status
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                              | Default  | Aliases/Examples |
| ------------------------ | -------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `OPENBOX_VERSION`        | Specific version of Openbox to install.                                                                  | `latest` |                  |
| `OPENBOX_INSTALL_METHOD` | How to install OPENBOX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
