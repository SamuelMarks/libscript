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

## Configuration Options

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default  | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `TMUX_INSTALL_METHOD` | How to install TMUX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `TMUX_VERSION`        | Specific version of tmux to install.                                                                                                                                 | `latest` |                  |
| `TMUX_DOWNLOAD_URL`   | Override URL for downloading tmux binary or archive artifacts.                                                                                                       | `none`   |                  |
| `TMUX_RELEASES_URL`   | Override URL for querying tmux available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
