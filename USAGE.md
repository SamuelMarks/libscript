# Usage Guide

LibScript provides a unified interface for provisioning software across Linux, Windows, macOS, and BSD. All commands have strict parity across `./libscript.sh` (POSIX) and `libscript.cmd` (Windows).

## Native Component Installation

Install individual components with optional versioning:

```sh
# POSIX
./libscript.sh install nodejs 20
./libscript.sh install postgres latest

# Windows
libscript.cmd install python 3.11
```

## ☸️ Declarative Stack Provisioning

For complex stacks, LibScript uses a declarative `libscript.json` and a built-in resolution engine.

### Defining Your Stack

Create a `libscript.json` to define your dependencies, including version constraints like `>16`, `~20`, or specific version aliases.

```json
{
  "deps": {
    "postgres": ">14",
    "valkey": "latest",
    "python": "3.11"
  }
}
```

### Provisioning Locally

Use the `install-deps` command to automatically resolve and install the entire stack.

```sh
# This resolves constraints, downloads binaries, and runs setup for all components
./libscript.sh install-deps
```

*Note: The resolution engine ensures that provided capabilities (e.g., "database") and port conflicts are addressed before installation begins.*

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
