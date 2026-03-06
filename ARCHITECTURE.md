# Architecture

LibScript is a framework for cross-platform software provisioning and packaging, built on zero-dependency shell scripts. Its architecture consists of a routing execution layer that delegates to modular components.

## The Core

The framework uses native shell scripts (`sh` for POSIX systems, `cmd` and `bat` for Windows) to ensure it can run in environments without pre-installed language runtimes (like Python, Ruby, or Go).

## Component Modules

Components (like databases, web servers, or language toolchains) are organized within the `_lib` directory. Each component contains:
- `vars.schema.json`: A strictly typed definition of the component's dependencies, environment variables, and metadata.
- `setup.sh`: A POSIX shell script to download, configure, and install the component.
- `setup_win.ps1` or `setup_win.cmd`: The equivalent installation script for Windows environments.
- Optional daemon or service configurations.

## Dynamic Resolution

When a user requests a stack (either via the CLI or a `libscript.json` definition), LibScript parses the component schemas, resolves their cross-platform system dependencies, and constructs an execution graph.

## The Generator Engine (`package_as`)

Because LibScript maintains a full model of each component's requirements, it can perform alternative operations beyond native installation. The generator engine can output:
- Dockerfiles
- `docker-compose.yml` configurations
- Native Windows installers (MSI via WiX, InnoSetup, NSIS)
- Native Linux and BSD packages (DEB, RPM, APK, TXZ)
- macOS installers (PKG, DMG)
