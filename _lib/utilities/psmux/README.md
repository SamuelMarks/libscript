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

## Architecture

`libscript` manages `psmux` versions natively by default (`PSMUX_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages psmux versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/psmux/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
