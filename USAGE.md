# Usage Guide

LibScript provides a unified interface for provisioning software across Linux, Windows, macOS, and BSD. All commands have strict parity across `./libscript.sh` (POSIX) and `libscript.cmd` (Windows).

## Native Component Installation

LibScript treats every component as a standalone package manager. You can manage tools either through the **Global Orchestrator** or via the **Local CLI** within each component's directory.

### Global Orchestrator
The global CLI (`libscript.sh` / `libscript.cmd`) handles routing, orchestration, and complex version resolution for you.

```sh
# POSIX
./libscript.sh install nodejs 20
./libscript.sh install postgres latest

# Windows
libscript.cmd install python 3.11
```

### Local Component CLI
Every component is an autonomous package manager. This approach is ideal for managing a single tool or when working within a specific component's directory.

```sh
# POSIX (navigate to component directory or call directly)
./_lib/languages/nodejs/cli.sh install nodejs 20
./_lib/databases/postgres/cli.sh install postgres latest

# Windows
_lib\languages\python\cli.cmd install python 3.11
```

## ☸️ Declarative Stack Provisioning

For complex stacks, LibScript uses a declarative `libscript.json` and a built-in resolution engine.

### Defining Your Stack

Create a `libscript.json` to define your dependencies, including version constraints like `>16`, `~20`, or specific version aliases.

```json
{
  "name": "my-app",
  "domain": "myapp.example.com",
  "dependencies": {
    "toolchains": [
      { "name": "python", "version": "3.12" }
    ],
    "servers": [
      { "name": "nginx", "ports": [80, 443] }
    ]
  },
  "hooks": {
    "build": [
      { "name": "compile", "command": "npm run build" }
    ],
    "pre_start": [
      { 
        "name": "migrate", 
        "command": "python manage.py migrate",
        "condition": "unless_exists /data/db.sqlite3"
      }
    ]
  },
  "services": [
    {
      "name": "backend",
      "command": "uvicorn main:app --port 8000",
      "env": { "ENV": "prod" }
    }
  ],
  "ingress": {
    "tls": "letsencrypt",
    "routes": [
      { "path": "/api/", "proxy_pass": "http://127.0.0.1:8000/" },
      { "path": "/", "root": "./web/dist", "try_files": "$uri $uri/ /index.html" }
    ]
  }
}
```

### Provisioning & Lifecycle

Use `install-deps` to automatically resolve and install the stack requirements natively on your machine, followed by `start` to orchestrate your app.

```sh
# 1. Resolves constraints, downloads binaries, and runs setups
./libscript.sh install-deps

# 2. Runs hooks (build, pre_start), daemonizes services (systemd/launchd), configures Nginx, and starts background jobs.
./libscript.sh start
```

*Note: LibScript acts as a native PaaS. The `start` command automatically translates your `services` into system daemons and configures your `ingress` routes via Nginx.*


## 🏗️ Artifact Generation (`package_as`)

Generate production-ready artifacts from your current stack definition.

### Generate a Dockerfile
```sh
./libscript.sh package_as docker
```

### Generate a Windows Installer (.msi)
```sh
# This transforms your shell logic into a WiX-based MSI installer
./libscript.sh package_as msi
```

## 🌍 Cloud Orchestration

LibScript wraps official cloud vendor CLIs into a unified, idempotent interface.

```sh
# Create a Jump-box on AWS
./libscript.sh cloud aws jumpbox create my-jumpbox

# Provision a 5-node group on GCP pre-installed with your stack
./libscript.sh cloud gcp node-group create web-tier 5 \
  --bootstrap "./libscript.sh install-deps"
```

### Application Deployment & DNS
LibScript provides built-in primitives to push applications and map domains to node IPs.

```sh
# Deploy your codebase to a remote Azure node (uses rsync and respects .gitignore)
./libscript.sh cloud azure node deploy my-vm t1d-rg ./src ~/app

# Securely copy a specific secrets file to an AWS node
./libscript.sh cloud aws node scp my-vm ./secrets/backend.env ~/app/secrets/backend.env

# Map a cloud node's IP to a domain name via Cloud DNS
./libscript.sh cloud gcp dns map-node my-vm us-central1-a my-domain.com my-managed-zone
```

### Resource Cleanup
LibScript automatically tags all cloud resources (`ManagedBy=LibScript`) for safe deprovisioning.
```sh
# List all managed resources across all providers
./libscript.sh cloud list-managed

# Safe cleanup (leaves data buckets untouched)
./libscript.sh cloud cleanup
```

## 🛠️ Service Management

All components support standard lifecycle commands:

```sh
./libscript.sh start postgres
./libscript.sh status nodejs
./libscript.sh logs -f valkey
./libscript.sh stop all
```
