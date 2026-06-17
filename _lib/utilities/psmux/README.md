# psmux Component

## Overview

This component installs `psmux`, a native Windows terminal multiplexer (born in PowerShell, made in
Rust). It serves as the Windows counterpart to `tmux` in the libscript ecosystem.

## Usage

```bash
# Start a new session
psmux new-session -d -s my-session

# Attach to a session
psmux attach-session -t my-session
```

## Environment Variables

| Variable        | Description                 | Default  |
| --------------- | --------------------------- | -------- |
| `PSMUX_VERSION` | Version of psmux to install | `v3.3.6` |
