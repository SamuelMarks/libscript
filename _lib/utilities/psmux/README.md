# psmux Component

## Overview

This component installs `psmux`, a native Windows terminal multiplexer (born in PowerShell, made in
Rust). It serves as the Windows counterpart to `tmux` in the libscript ecosystem.

## Usage

_Note: libscript manages versions natively for this component._

```bash
# Start a new session
psmux new-session -d -s my-session

# Attach to a session
psmux attach-session -t my-session
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PSMUX_INSTALL_METHOD` | How to install PSMUX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `PSMUX_VERSION`        | Version of psmux to install                                                                                                                                           | `v3.3.6`           |                  |
| `PSMUX_DOWNLOAD_URL`   | Override URL for downloading psmux binary or archive artifacts.                                                                                                       | `none`             |                  |
| `PSMUX_RELEASES_URL`   | Override URL for querying psmux available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
