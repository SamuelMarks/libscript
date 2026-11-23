# JACK Audio Connection Kit (`_lib/audio/jack/`)

## Overview

JACK2 low-latency professional real-time audio and MIDI server daemon (jackd).

- **Tier**: `T2` (`_lib/audio/jack/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `jack`, `jack2`, `jackd`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install jack latest
./libscript.sh jack --help
./_lib/audio/jack/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd jack --help
.\_lib\audio\jack\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `JACK_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `JACK_INSTALL_METHOD` | How to install jack. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `JACK_VERSION`        | Specific version of jack to install.                                                                                                          | `latest`           | latest, stable   |
| `JACK_DOWNLOAD_URL`   | Override URL for downloading jack binary or archive artifacts.                                                                                | `none`             |                  |
| `JACK_RELEASES_URL`   | Override URL for querying jack available remote releases.                                                                                     | `none`             |                  |
| `JACK_LISTEN_PORT`    | TCP port on which the jack service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
