# Wayland, Seat Management & X11 Display Servers (`_lib/display-servers/`)

## Overview

**Tier Scope**: `T2`

Core display protocol libraries, seat multiplexers, and X11/Wayland servers (`wayland`,
`wayland-protocols`, `wlroots`, `seatd`, `libseat`, `libxkbcommon`, `xorg-server`, `xwayland`).

Each subdirectory in `_lib/display-servers/` is an atomic, self-contained LibScript component
governed by its own `manifest.json` and `vars.schema.json`. Components in `_lib/display-servers/`
never cross-source sibling components directly; instead, they source `T0` helpers from
`engine/common/` and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5`
(`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh libseat --help
./libscript.sh install libseat latest
./_lib/display-servers/libseat/cli.sh test
```

```cmd
.\libscript.cmd libseat --help
.\libscript.cmd install libseat latest
.\_lib\display-servers\libseat\cli.cmd test
```

## Components (8)

<!-- BEGIN_COMPONENTS -->

- [`libseat`](./libseat/README.md) (`T2` — `sysroot-package`, `service-daemon`): Universal seat
  management client library
- [`libxkbcommon`](./libxkbcommon/README.md) (`T2` — `sysroot-package`, `service-daemon`): Keyboard
  description parser and keymap library
- [`seatd`](./seatd/README.md) (`T2` — `sysroot-package`, `service-daemon`): Minimal seat management
  daemon and library
- [`wayland`](./wayland/README.md) (`T2` — `sysroot-package`, `service-daemon`): Core Wayland
  display server library and protocols
- [`wayland-protocols`](./wayland-protocols/README.md) (`T2` — `sysroot-package`, `service-daemon`):
  Official protocol extensions for Wayland
- [`wlroots`](./wlroots/README.md) (`T2` — `sysroot-package`, `service-daemon`): Modular Wayland
  compositor library
- [`xorg-server`](./xorg-server/README.md) (`T2` — `sysroot-package`, `service-daemon`): Traditional
  X Window System display server
- [`xwayland`](./xwayland/README.md) (`T2` — `sysroot-package`, `service-daemon`): X11 server
  running as a Wayland client

<!-- END_COMPONENTS -->
