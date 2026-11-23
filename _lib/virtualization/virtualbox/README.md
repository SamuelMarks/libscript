# VirtualBox Component

**Tier**: `T1` (`_lib/virtualization/virtualbox/`) | **Capabilities**: `userland-package`

Installs and configures Oracle VM VirtualBox 7.0+ with Oracle Extension Pack (TPM 2.0 and Secure
Boot support).

## Usage

```sh
# Install VirtualBox and Extension Pack
./libscript.sh install virtualbox

# Test VirtualBox installation
./libscript.sh test virtualbox
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                     | Description                                          | Default  | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------- | -------- | ---------------- |
| `VIRTUALBOX_VERSION`         | Version of VirtualBox (e.g. 7.0, latest)             | `7.0`    |                  |
| `VIRTUALBOX_INSTALL_METHOD`  | Install method for VirtualBox (system, brew)         | `system` |                  |
| `VIRTUALBOX_INSTALL_EXTPACK` | Install Oracle VM VirtualBox Extension Pack (1 or 0) | `1`      |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
