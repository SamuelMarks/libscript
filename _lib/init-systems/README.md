# PID 1 Init Systems & Service Supervisors (`_lib/init-systems/`)

## Overview

**Tier Scope**: `T2`

Operating system init systems and cross-platform daemon supervisors (`systemd`, `openrc`, `runit`,
`s6`, `dinit`, `sysvinit`, `launchd`, `smf`, `windows-scm`, `nssm`, `supervisord`).

Each subdirectory in `_lib/init-systems/` is an atomic, self-contained LibScript component governed
by its own `manifest.json` and `vars.schema.json`. Components in `_lib/init-systems/` never
cross-source sibling components directly; instead, they source `T0` helpers from `engine/common/`
and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and
`Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh dinit --help
./libscript.sh install dinit latest
./_lib/init-systems/dinit/cli.sh test
```

```cmd
.\libscript.cmd dinit --help
.\libscript.cmd install dinit latest
.\_lib\init-systems\dinit\cli.cmd test
```

## Components (11)

<!-- BEGIN_COMPONENTS -->

- [`dinit`](./dinit/README.md) (`T2` — `sysroot-package`, `service-daemon`): Service manager and
  dependency-aware init system for Unix-like operating systems.
- [`launchd`](./launchd/README.md) (`T2` — `sysroot-package`, `service-daemon`): macOS and Darwin
  launchd Property List (plist) service manager adapter and launchctl lifecycle bridge.
- [`nssm`](./nssm/README.md) (`T2` — `sysroot-package`, `service-daemon`): Windows service wrapper
  and daemon supervisor for running native Win64 binaries (Waitress, Celery, Caddy, Meilisearch) as
  resilient Windows Services.
- [`openrc`](./openrc/README.md) (`T2` — `sysroot-package`, `service-daemon`): This document
  describes the **OpenRC** component (part of the `_daemon` stack) within the LibScript ecosystem.
  OpenRC is a dependency-based init system that works with the system-provided init program.
- [`runit`](./runit/README.md) (`T2` — `sysroot-package`, `service-daemon`): Cross-platform Unix
  init scheme with service supervision.
- [`s6`](./s6/README.md) (`T2` — `sysroot-package`, `service-daemon`): skarnet.org small and secure
  supervision suite and init system.
- [`smf`](./smf/README.md) (`T2` — `sysroot-package`, `service-daemon`): illumos and Solaris Service
  Management Facility (SMF) manifest and service control adapter (svcadm, svccfg, svcs).
- [`supervisord`](./supervisord/README.md) (`T2` — `sysroot-package`, `service-daemon`): Supervisor
  client/server process control daemon (supervisord and supervisorctl) for UNIX-like operating
  systems.
- [`systemd`](./systemd/README.md) (`T2` — `sysroot-package`, `service-daemon`): systemd
- [`sysvinit`](./sysvinit/README.md) (`T2` — `sysroot-package`, `service-daemon`): Traditional
  System V style init program and runlevel controller.
- [`windows-scm`](./windows-scm/README.md) (`T2` — `sysroot-package`, `service-daemon`): Windows
  Service Control Manager (SCM / sc.exe) native service lifecycle adapter and cross-platform
  compatibility shim.

<!-- END_COMPONENTS -->
