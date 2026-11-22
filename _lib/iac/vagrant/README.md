# Vagrant Component

Installs HashiCorp Vagrant via official repository, brew, or native release binary, and configures
the `vagrant-libvirt` provider plugin.

## Usage

```sh
# Install Vagrant
./libscript.sh install vagrant

# Verify installation
./libscript.sh test vagrant
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                         | Description                                                     | Default  | Aliases/Examples |
| -------------------------------- | --------------------------------------------------------------- | -------- | ---------------- |
| `VAGRANT_VERSION`                | Version of Vagrant (default: latest)                            | `latest` |                  |
| `VAGRANT_INSTALL_METHOD`         | Install method for Vagrant (system, brew, libscript_native)     | `system` |                  |
| `VAGRANT_INSTALL_LIBVIRT_PLUGIN` | Install vagrant-libvirt plugin (1 or 0)                         | `1`      |                  |
| `VAGRANT_INSTALL_QEMU_PLUGIN`    | Configuration variable VAGRANT_INSTALL_QEMU_PLUGIN for vagrant. | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
