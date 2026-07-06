# tmux Component

## Overview

This component manages the installation and execution of `tmux` within the libscript
ecolibscript_native. It provides CLI wrappers to launch detached sessions, which is crucial for
execution resilience. If your SSH connection drops during a long-running ML training job, the `tmux`
session keeps the process alive.

## Usage

_Note: libscript manages versions natively for this component._

Refer to the component's setup and cli scripts for specific operations.

```bash
# Create a detached session running a command
./_lib/utilities/tmux/cli.sh new-session my-training-job "python train.py"

# Attach to the session later
./_lib/utilities/tmux/cli.sh attach my-training-job
```

## Environment Variables

This component honors standard `libscript` variables. Refer to `_common/base_vars.schema.json`.

## Configuration

| Variable              | Description                                                                                                                                                          | Default            | Required |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `TMUX_INSTALL_METHOD` | How to install TMUX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages tmux versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/tmux/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
