# CLI Subcommand Modules (`cli/commands/`)

## Overview

`cli/commands/` contains the core cross-platform (`POSIX .sh`, `Windows .cmd`, and `.ps1`) CLI
subcommand handlers sourced or executed by `libscript.sh` and `libscript.cmd`.

## Submodules

- **`config/`**: OS synthesis configurator (`config.{sh,cmd,ps1}`), terminal UI engine
  (`tui_engine.{sh,cmd,ps1}`), and Linux From Scratch profile validator
  (`validate_lfs_profile.{sh,cmd}`).
- **`core/`**: Catalog listing (`list.*`), manifest keyword search (`search.*`), semantic version
  comparison (`semver.*`), and framework version reporting (`version.*`).
- **`deps/`**: Stack dependency graph installation (`install.*` via `libscript install-deps`) and
  batch download queue processing (`process_downloads.*`).
- **`registry/`**: Local/remote component registry search (`search.*`) and index updates
  (`update.*`).
- **`scaffold/`**: Interactive and schema-driven (`component-scaffold.schema.json`) component
  scaffolder (`scaffold.*` via `libscript scaffold` or `libscript new-component`).
- **`resolve_env.{sh,cmd}`**: Evaluates workspace pinfiles (`.libscript-version`, `.nvmrc`,
  `.python-version`, `rust-toolchain.toml`, `libscript.json`) and emits shell-compatible environment
  exports.

## Usage

```sh
./libscript.sh list
./libscript.sh search postgres
./libscript.sh resolve-env --shell=posix
./libscript.sh config os --profile=linux-minimal-headless-musl --export=os.json
./libscript.sh scaffold --help
```

```cmd
.\libscript.cmd list
.\libscript.cmd search postgres
.\libscript.cmd resolve-env --shell=cmd
.\libscript.cmd config os --profile=linux-minimal-headless-musl --export=os.json
.\libscript.cmd scaffold --help
```
