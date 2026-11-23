# Core Catalog & Versioning Commands (`cli/commands/core/`)

## Overview

`cli/commands/core/` provides foundational CLI discovery and version-comparison operations invoked
by `libscript.sh` and `libscript.cmd`.

## Scripts

- **`list.{sh,cmd,ps1}`**: Discovers and lists all available components across `_lib/` and domain
  subsystems, grouped by category.
- **`search.{sh,cmd,ps1}`**: Searches component names, categories, titles, and `manifest.json`
  descriptions for matching keywords.
- **`semver.{sh,cmd,ps1}`**: Compares and sorts semantic version strings and constraint ranges
  (backed by `engine/common/semver.{jq,sh,cmd}`).
- **`version.{sh,cmd,ps1}`**: Prints the active LibScript engine version and commit metadata.

## Usage

```sh
./libscript.sh list
./libscript.sh search valkey
./libscript.sh --version
```

```cmd
.\libscript.cmd list
.\libscript.cmd search valkey
.\libscript.cmd --version
```
