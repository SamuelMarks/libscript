# Audio & Multimedia Stack (`_lib/audio/`)

## Overview

**Tier Scope**: `T1 / T2`

Kernel/userspace sound libraries, low-latency multimedia graph routers (`pipewire`, `wireplumber`,
`jack`, `pulseaudio`, `sndio`), and ALSA sysroot components.

Each subdirectory in `_lib/audio/` is an atomic, self-contained LibScript component governed by its
own `manifest.json` and `vars.schema.json`. Components in `_lib/audio/` never cross-source sibling
components directly; instead, they source `T0` helpers from `engine/common/` and are composed upward
by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh alsa-lib --help
./libscript.sh install alsa-lib latest
./_lib/audio/alsa-lib/cli.sh test
```

```cmd
.\libscript.cmd alsa-lib --help
.\libscript.cmd install alsa-lib latest
.\_lib\audio\alsa-lib\cli.cmd test
```

## Components (8)

<!-- BEGIN_COMPONENTS -->

- [`alsa-lib`](./alsa-lib/README.md) (`T2` — `sysroot-package`): Advanced Linux Sound Architecture
  userland library
- [`alsa-ucm-conf`](./alsa-ucm-conf/README.md) (`T2` — `sysroot-package`): ALSA Use Case Manager
  configuration files
- [`alsa-utils`](./alsa-utils/README.md) (`T2` — `sysroot-package`): Command-line tools for ALSA
  sound subsystem
- [`jack`](./jack/README.md) (`T2` — `sysroot-package`): JACK2 low-latency professional real-time
  audio and MIDI server daemon (jackd).
- [`pipewire`](./pipewire/README.md) (`T2` — `sysroot-package`): Modern multimedia graph processing
  server
- [`pulseaudio`](./pulseaudio/README.md) (`T2` — `sysroot-package`): Networked sound server daemon
- [`sndio`](./sndio/README.md) (`T2` — `sysroot-package`): Lightweight OpenBSD audio and MIDI server
  daemon and library (sndiod, aucat, sndioctl).
- [`wireplumber`](./wireplumber/README.md) (`T2` — `sysroot-package`): Modular session and policy
  manager for PipeWire

<!-- END_COMPONENTS -->
