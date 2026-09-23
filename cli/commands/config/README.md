# LibScript Configuration Commands (`config`)

## Overview

Provides commands for reading, querying, updating, and listing configuration variables across
LibScript components and local installations.

## Commands

- `get`: Retrieve the current value of a configuration setting.
- `set`: Update a configuration key with a new value.
- `list`: Enumerate all configured variables and environment properties.

## Usage

```sh
# Query configuration
./libscript.sh config get MYSQL_PORT

# Set configuration variable
./libscript.sh config set MYSQL_PORT 3306

# List all configuration
./libscript.sh config list
```
