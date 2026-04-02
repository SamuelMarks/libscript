Serve Actix Diesel Auth Scaffold
================================

## Purpose & Overview
This document describes the `serve-actix-diesel-auth-scaffold` component within the LibScript ecosystem. This component acts as a scaffolding tool and template for Rust-based web applications using Actix, Diesel, and authentication middleware.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript` command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for this component. You can manage `serve-actix-diesel-auth-scaffold` directly in an isolated, local context, or orchestrate it globally. 

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger, complex stacks (like WordPress, Open edX, Nextcloud, custom SaaS platforms, etc.) by defining it as a dependency in your deployment configurations.

## Usage
You can easily install, uninstall, start, stop, and package this component using the LibScript CLI:

### Installation
**Unix (Linux/macOS):**
```sh
./cli.sh install serve-actix-diesel-auth-scaffold 

libscript install serve-actix-diesel-auth-scaffold
```
**Windows:**
```cmd
cli.cmd install serve-actix-diesel-auth-scaffold 

libscript.cmd install serve-actix-diesel-auth-scaffold
```

### Start & Stop
```sh
./cli.sh start serve-actix-diesel-auth-scaffold
./cli.sh stop serve-actix-diesel-auth-scaffold
```

### Uninstallation
```sh
./cli.sh uninstall serve-actix-diesel-auth-scaffold
```

### Packaging
LibScript can package this component into various deployment formats:
```sh
libscript package_as docker serve-actix-diesel-auth-scaffold
libscript package_as msi serve-actix-diesel-auth-scaffold
```

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct installation script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
