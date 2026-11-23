# PipeWire Audio

**Tier**: `T2` (`_lib/audio/pipewire/`) | **Capabilities**: `sysroot-package`

Modern multimedia graph processing server

## Usage

```sh
./libscript.sh install pipewire
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                               | Default  | Aliases/Examples |
| ------------------------- | --------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PIPEWIRE_VERSION`        | Specific version of pipewire to install.                                                                  | `latest` |                  |
| `PIPEWIRE_INSTALL_METHOD` | How to install PIPEWIRE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
