# Plane A Automated Maintenance & Hygiene Trait (`traits/maintenance/`)

## Overview

`traits/maintenance/` registers recurring operational hygiene jobs across `T3` offline sysroots and
`T4`/`T5` live hosts without requiring external job schedulers.

## Scripts

- **`schedule.{sh,cmd}`**: Emits `systemd` `.service`/`.timer` units, POSIX `cron.d` schedules,
  macOS `launchd` plists, or Windows `schtasks` entries for automated TLS certificate renewal
  (`cert-renew`), log rotation (`log-rotate`), database vacuum/compaction (`db-vacuum`), and backup
  retention pruning (`backup-prune`).

## Usage

```sh
./libscript.sh trait apply maintenance
./libscript.sh trait verify maintenance
```
