# tmux Component

## Overview

This component manages the installation and execution of `tmux` within the libscript ecosystem. It
provides CLI wrappers to launch detached sessions, which is crucial for execution resilience. If
your SSH connection drops during a long-running ML training job, the `tmux` session keeps the
process alive.

## Usage

Refer to the component's setup and cli scripts for specific operations.

```bash
# Create a detached session running a command
./_lib/utilities/tmux/cli.sh new-session my-training-job "python train.py"

# Attach to the session later
./_lib/utilities/tmux/cli.sh attach my-training-job
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.
