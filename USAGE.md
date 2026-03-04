# Usage Guide

## Purpose & Current State

**Purpose**: This document is a comprehensive user guide covering component installation, environment configuration, global command aliases (`run`, `exec`, `which`), and advanced JSON-based declarative deployments. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: The CLI is fully functional for imperative installations (`install`, `search`, `list`), environment querying (`env`), and global path execution (`run`, `exec`, `which`). The declarative JSON processing (`install.json`) is stable, enabling users to provision complex, multi-component environments with native caching and secret generation hooks.

## Global Invocation

The `libscript.sh` script acts as a router to find and execute the correct component.

```sh
# List all installable components
./libscript.sh list

# Search for a component by name or description
./libscript.sh search postgres
```

### Installing a Component

To install a component, pass its name to the CLI:

```sh
./libscript.sh install rust latest
./libscript.sh install postgres 16
./libscript.sh install nginx 1.25
```

### Accessing Component Environment

You can extract the shell environment variables exported by a component (like its internal `PATH` addition or `DATABASE_URL`) using the `env` subcommand:

```sh
# Print the export commands
./libscript.sh env postgres 16

# Source them into your current shell
eval $(./libscript.sh env postgres 16)
```

### Passing Options

Components can be customized using command-line arguments. To see available options for a specific component, use the `--help` flag:

```sh
./libscript.sh install postgres 16 --help
```

Output example:
```
  --POSTGRES_USER=VALUE               The default database user [default: postgres]
  --POSTGRES_PASSWORD=VALUE           The default database password [default: none]
  --POSTGRES_PORT=VALUE               The port to bind to [default: 5432]
```

You can then apply these arguments:

```sh
./libscript.sh install postgres 16 --POSTGRES_USER=admin --POSTGRES_PORT=5433
```

## Environment Variables

LibScript relies heavily on environment variables for configuration state. When you pass `--KEY=VALUE` to the CLI, it simply exports `KEY=VALUE` into the environment before running the setup script.

You can also export these variables manually:

```sh
export POSTGRES_USER=admin
export POSTGRES_PORT=5433
./libscript.sh install postgres 16
```

## Advanced Installation via JSON (`install.json`)

For deploying complex environments, you can define an `install.json` file that specifies which components to install and what their configuration should be, and process it with `create_installer_from_json.sh` or `parse_installer_json.sh`. This provides an Ansible-like declarative approach while utilizing purely shell-script execution underneath.

## Enhanced Global Commands

The libscript suite has been enhanced globally to standardize path environments and application caches:
- `install <package> <version>` : Implemented. Accepts `--prefix` to redirect local installations.
- `run <package> <version> [args]` : Executes the selected versioned binary silently via configured execution layers.
- `exec <package> <version> <cmd>` : Executes an arbitrary command scoped to the runtime path.
- `which <package> <version>` : Echoes binary path securely.
- `ls <package>` : Output current caching instances.
- `ls-remote <package>` : Scans available network architectures if enabled.

Global Options:
- `--cache-dir=<dir>` : Rebind internal caching from ROOT/cache/downloads.
- `--prefix=<dir>` : Relocate local package directory from internally routed target directories.
- `--secrets=<dir|url>` : Set global output path for generated environments or OpenBao/Vault URL. Defaults to ROOT/secrets.

All components inherit this architecture cleanly across both `sh` and Windows `.cmd`.

