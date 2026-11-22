# Packer Component

Installs HashiCorp Packer via official repository, brew, or native release binary.

## Usage

```sh
# Install Packer
./libscript.sh install packer

# Verify installation
./libscript.sh test packer
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                | Description                                                | Default  | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------- | -------- | ---------------- |
| `PACKER_VERSION`        | Version of Packer (default: latest)                        | `latest` |                  |
| `PACKER_INSTALL_METHOD` | Install method for Packer (system, brew, libscript_native) | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
