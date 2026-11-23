# OS Synthesis Profile Configurator & TUI Engine (`cli/commands/config/`)

## Overview

`cli/commands/config/` implements `./libscript.sh config os` (`libscript.cmd config os`), providing
both an interactive Terminal User Interface (TUI) and non-interactive CLI flags for loading,
customizing, validating, and exporting `T3` operating system synthesis configurations governed by
`synthesis/schemas/os-config.schema.json`.

## Scripts

- **`config.{sh,cmd,ps1}`**: Loads curated OS profiles from `synthesis/profiles/`, validates JSON
  configurations against `synthesis/schemas/os-config.schema.json`, launches interactive menu
  configuration, and exports portable `os-config.json` manifests.
- **`tui_engine.{sh,cmd,ps1}`**: Portable terminal dialog abstraction supporting pure ANSI VT100
  menus alongside `whiptail` and `dialog` when available.
- **`validate_lfs_profile.{sh,cmd}`**: Validates Linux From Scratch
  (`synthesis/profiles/lfs/*.json`) multi-stage bootstrap profiles, init-system pairings, and
  libc/toolchain invariants.

## Usage

```sh
# Launch the interactive OS configurator TUI
./libscript.sh config os

# Load a curated profile from synthesis/profiles/ and export a standalone config
./libscript.sh config os --profile=linux-desktop-sway-wayland --export=my-os.json

# Validate an OS configuration JSON file
./libscript.sh config os --validate=my-os.json
```

```cmd
.\libscript.cmd config os --profile=freebsd-server-standard --export=freebsd-os.json
.\libscript.cmd config os --validate=freebsd-os.json
```
