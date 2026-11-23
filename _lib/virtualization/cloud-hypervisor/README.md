# Cloud Hypervisor

**Tier**: `T1` (`_lib/virtualization/cloud-hypervisor/`) | **Capabilities**: `userland-package`

Cloud Hypervisor component for LibScript systems.

## Usage

```sh
./libscript.sh install cloud-hypervisor
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                          | Description                                                                                                       | Default  | Aliases/Examples |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CLOUD_HYPERVISOR_VERSION`        | Specific version of cloud-hypervisor to install.                                                                  | `latest` |                  |
| `CLOUD_HYPERVISOR_INSTALL_METHOD` | How to install CLOUD_HYPERVISOR. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
