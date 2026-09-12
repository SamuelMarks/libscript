# LibScript Service Management Commands

## Overview

Controls local daemon lifecycle across supported init systems (systemd, launchd, OpenRC, and Windows
Services).

## Subcommands

- `start`: Starts configured component daemons.
- `stop`: Gracefully stops running services.
- `restart`: Restarts services and reloads configuration.
- `status`: Queries daemon execution state and PID.
- `health`: Executes component health checks.
- `logs`: Displays and streams service stdout/stderr logs.
