# Usage Guide

LibScript is designed to be invoked globally via the `libscript.sh` (Unix) or `libscript.cmd` (Windows) entrypoints, or locally by directly running a component's `cli.sh`.

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

All components inherit this architecture cleanly across both `sh` and Windows `.cmd`.
