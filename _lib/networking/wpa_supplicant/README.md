# WPA Supplicant

**Tier**: `T2` (`_lib/networking/wpa_supplicant/`) | **Capabilities**: `sysroot-package`

WPA/WPA2/WPA3 wireless security daemon

## Usage

```sh
./libscript.sh install wpa_supplicant
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                     | Default  | Aliases/Examples |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `WPA_SUPPLICANT_VERSION`        | Specific version of wpa_supplicant to install.                                                                  | `latest` |                  |
| `WPA_SUPPLICANT_INSTALL_METHOD` | How to install WPA_SUPPLICANT. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
