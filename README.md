# LibScript

[![CI Status](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

LibScript is a cross-platform software provisioning framework, stack generator, universal version manager, and multicloud orchestrator. It operates entirely on zero-dependency shell scripts (`sh`, `cmd`, `bat`), providing a lightweight alternative to heavy configuration managers and a native complement to containerized environments.

## Core Capabilities

- **Universal Package & Version Manager:** LibScript functions as a granular version manager for individual languages and tools (e.g., "just Postgres", "just Nginx"). It allows side-by-side installations of different versions without system-wide conflicts.
- **Artifact Generation Engine:** Use the `package_as` command to automatically export your local stack into various production-ready formats:
  - **Containers:** `Dockerfile`, `docker-compose.yml`
  - **Windows:** `.msi` (WiX), `.exe` (InnoSetup, NSIS)
  - **Linux/BSD:** `.deb`, `.rpm`, `.apk`, `.txz`
  - **macOS:** `.pkg`, `.dmg`
- **Multicloud Orchestration:** Provision, deprovision, and audit infrastructure across AWS, Azure, and Google Cloud Platform via a unified interface. Supports `node-group` management, automated bootstrapping, and flexible resource tagging.
- **Native PaaS:** Evolving into a full-featured Platform-as-a-Service, LibScript handles end-to-end deployment from infrastructure provisioning to application-level sidecar services and scheduled backups.
- **Zero-Dependency Architecture:** Requires no Python, Ruby, or Go agents to bootstrap. Pure POSIX shell and Windows CMD.

## Lifecycle Commands

LibScript provides a unified interface for managing individual components, entire stacks, or cloud infrastructure.

**Native Management:**
```sh
./libscript.sh install <COMPONENT> [VERSION]
./libscript.sh start <COMPONENT>
./libscript.sh package_as msi <COMPONENT>
```

**Cloud Management:**
```sh
./libscript.sh cloud <provider> <resource> create <name> [args...]
./libscript.sh cloud list-managed [tag_filter]
./libscript.sh cloud cleanup [--force-buckets]
```

## Quick Start

List the supported components and cloud providers:

```sh
./libscript.sh list
```

Provision a 3-node Nginx group on AWS with a custom tag:

```sh
./libscript.sh cloud aws node-group create web-nodes 3 ami-ubuntu-lts my-vpc \
  --tags "Project=Alpha" --bootstrap "libscript.sh install nginx"
```

For more details on building complex stacks and utilizing the generator engine, refer to `USAGE.md` and `_lib/cloud/DOCS.md`.
