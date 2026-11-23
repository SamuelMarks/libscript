# Component Registry & Index Commands (`cli/commands/registry/`)

## Overview

`cli/commands/registry/` manages local component catalog indices, SQLite/JSON metadata caches, and
upstream release table refreshes.

## Scripts

- **`search.{sh,cmd,ps1}`**: Queries indexed component manifests and cached release metadata for
  matching packages and capabilities.
- **`update.{sh,cmd,ps1}`**: Rebuilds local component registry indices from `_lib/*/*/manifest.json`
  and refreshes cached upstream release tables when online.

## Usage

```sh
./cli/commands/registry/update.sh
./cli/commands/registry/search.sh python
```

```cmd
.\cli\commands\registry\update.cmd
.\cli\commands\registry\search.cmd python
```
