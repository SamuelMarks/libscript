# msi-rs Installation Engines

## Purpose & Overview

Provides interactive and automated user interfaces for the `msi-rs` installer ecosystem:

- Terminal User Interface (TUI) based on VT100 / dialog.
- Graphical User Interface (GUI) for desktop and live media environments.
- Non-interactive Headless installation engine driven by declarative JSON configuration.

## Usage

```sh
# Run Terminal User Interface installer
./tui.sh [--plan <path_to_execution_plan.json>]

# Run Graphical Installer
./gui.sh [--plan <path_to_execution_plan.json>]

# Run Headless unattended installer
./headless.sh --plan <path_to_execution_plan.json>
```

## Available Scripts

- `tui.sh` / `.cmd`: Interactive terminal-based installation wizard.
- `gui.sh` / `.cmd`: Graphical installer wizard.
- `headless.sh` / `.cmd`: Fully automated headless deployment runner.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
