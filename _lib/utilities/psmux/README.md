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

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
