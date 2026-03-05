# Usage Guide

## Purpose
A deep dive into how to use LibScript, covering CLI commands, environment scoping, background daemon management, and declarative manifests.

## What Makes LibScript's Usage Interesting?
LibScript can be used imperatively like `brew` or `apt` (e.g., `install rust latest`), but it also acts as a declarative orchestrator via `libscript.json`, a virtual environment manager (via `run`/`exec`), and an installer compiler (`package_as`).

## Core Commands
```sh
./libscript.sh list                # View all components
./libscript.sh search <query>      # Search components
./libscript.sh install <pkg> <ver> # Install a component
./libscript.sh env <pkg> <ver>     # Output environment variables
./libscript.sh run <pkg> <ver>     # Run a tool in its isolated environment
```

## Environment Scoping & Prefixes
You don't have to pollute your global system. Use `--prefix` to install tools locally.
```sh
./libscript.sh install nodejs 20 --prefix=/opt/myproject
./libscript.sh run nodejs 20 --prefix=/opt/myproject node index.js
```

## Service & Daemon Management
LibScript includes unified commands to manage background services, mapping them automatically to Systemd, OpenRC, or Windows Services.
```sh
./libscript.sh start postgres
./libscript.sh status postgres
./libscript.sh logs -f postgres
./libscript.sh stop postgres
```

## Component Dependencies & Strategy Overrides
When installing complex applications, LibScript parses the component's `vars.schema.json` to automatically resolve dependencies (like databases or web servers).

By default, the installer attempts to `reuse` any existing dependencies found on the system. You can interactively override the dependency and its resolution strategy via auto-generated CLI flags or environment variables:

```sh
# Override the default database dependency (e.g. mariadb -> postgres)
./libscript.sh install wordpress latest --WORDPRESS_DB=postgres

# Tell LibScript to install this dependency locally, even if a global version exists
./libscript.sh install wordpress latest --WORDPRESS_DB_STRATEGY=install-alongside

# Downgrade an existing installation, if necessary
./libscript.sh install wordpress latest --WORDPRESS_WEBSERVER_STRATEGY=downgrade
```

## Declarative Environments (`libscript.json`)
Create a `libscript.json` file to define your stack:
```json
{
  "deps": {
    "postgres": "16",
    "nodejs": "20",
    "nginx": "latest"
  }
}
```
Deploy the entire stack:
```sh
./libscript.sh install-deps libscript.json
```

## Deployment Artifact Generation (`package_as`)
Generate standard deployment configurations from your current environment dynamically:
```sh
# Generate a Docker Compose file
./libscript.sh package_as docker_compose postgres 16 nginx latest > docker-compose.yml

# Generate a Debian package
./libscript.sh package_as deb --app-name my-stack postgres 16
```
