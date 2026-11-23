# Wayland Compositors & X11 Desktop Environments (`_lib/desktops/`)

## Overview

**Tier Scope**: `T1 / T2`

Graphical desktop environments and tiling/stacking compositors (`kde-plasma-6`, `gnome`, `xfce4`,
`lxqt`, `mate`, `sway`, `hyprland`, `labwc`, `weston`, `i3`, `openbox`).

Each subdirectory in `_lib/desktops/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/desktops/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh gnome --help
./libscript.sh install gnome latest
./_lib/desktops/gnome/cli.sh test
```

```cmd
.\libscript.cmd gnome --help
.\libscript.cmd install gnome latest
.\_lib\desktops\gnome\cli.cmd test
```

## Components (11)

<!-- BEGIN_COMPONENTS -->

- [`gnome`](./gnome/README.md) (`T2` — `sysroot-package`): Modern desktop environment for Linux
- [`hyprland`](./hyprland/README.md) (`T2` — `sysroot-package`): Dynamic tiling Wayland compositor
  with animations
- [`i3`](./i3/README.md) (`T2` — `sysroot-package`): Dynamic tiling X11 window manager (i3, i3-msg,
  i3bar) designed for keyboard-driven workflows.
- [`kde-plasma-6`](./kde-plasma-6/README.md) (`T2` — `sysroot-package`): Feature-rich desktop
  workspace by KDE
- [`labwc`](./labwc/README.md) (`T2` — `sysroot-package`): Openbox-like stacking Wayland compositor
- [`lxqt`](./lxqt/README.md) (`T2` — `sysroot-package`): Lightweight Qt-based desktop environment
- [`mate`](./mate/README.md) (`T2` — `sysroot-package`): MATE Desktop Environment session manager,
  panel, and traditional GTK desktop suite (mate-session).
- [`openbox`](./openbox/README.md) (`T2` — `sysroot-package`): Highly configurable, next-generation
  X11 stacking window manager with extensive standards support.
- [`sway`](./sway/README.md) (`T2` — `sysroot-package`): i3-compatible tiling Wayland compositor
- [`weston`](./weston/README.md) (`T2` — `sysroot-package`): Reference Wayland compositor
  implementation
- [`xfce4`](./xfce4/README.md) (`T2` — `sysroot-package`): Fast and lightweight desktop environment

<!-- END_COMPONENTS -->
