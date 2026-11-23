# Graphical Display Managers & Login Greeters (`_lib/display-managers/`)

## Overview

**Tier Scope**: `T2`

Wayland and X11 session login managers (`greetd`, `sddm`, `gdm`, `lightdm`, `ly`).

Each subdirectory in `_lib/display-managers/` is an atomic, self-contained LibScript component
governed by its own `manifest.json` and `vars.schema.json`. Components in `_lib/display-managers/`
never cross-source sibling components directly; instead, they source `T0` helpers from
`engine/common/` and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5`
(`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh gdm --help
./libscript.sh install gdm latest
./_lib/display-managers/gdm/cli.sh test
```

```cmd
.\libscript.cmd gdm --help
.\libscript.cmd install gdm latest
.\_lib\display-managers\gdm\cli.cmd test
```

## Components (5)

<!-- BEGIN_COMPONENTS -->

- [`gdm`](./gdm/README.md) (`T2` — `sysroot-package`, `service-daemon`): GNOME Display Manager
  daemon
- [`greetd`](./greetd/README.md) (`T2` — `sysroot-package`, `service-daemon`): Minimal, generic and
  agnostic login daemon
- [`lightdm`](./lightdm/README.md) (`T2` — `sysroot-package`, `service-daemon`): Cross-desktop
  lightweight display manager
- [`ly`](./ly/README.md) (`T2` — `sysroot-package`, `service-daemon`): Lightweight ncurses-like
  terminal user interface (TUI) display manager for Linux and BSD supporting Wayland and X11.
- [`sddm`](./sddm/README.md) (`T2` — `sysroot-package`, `service-daemon`): QML-based modern display
  manager

<!-- END_COMPONENTS -->
