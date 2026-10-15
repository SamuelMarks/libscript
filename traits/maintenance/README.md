# Periodic Maintenance Scheduler Trait (`traits/maintenance/`)

## Overview

`traits/maintenance/` registers recurring execution of `hooks/maintenance.{sh,cmd}` and
`traits/backup/orchestrate.{sh,cmd}` via systemd `.timer` units, POSIX `crontab`
(`# BEGIN libscript-maintenance`), or Windows `schtasks.exe /create /f`, supporting both Tier 2
offline sysroot bake mode and Tier 3 live runtime mode.
