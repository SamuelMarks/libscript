# OpenVPN (Third-Party Application)

## Purpose & Overview

This document describes the `openvpn` networking and VPN component within the LibScript ecosystem.

LibScript functions as both a comprehensive global version manager (invoked via the `libscript` command) and a local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for OpenVPN. You can manage OpenVPN directly in an isolated, local context, or orchestrate it globally. 

Furthermore, this component can be seamlessly utilized by LibScript to build and provision larger, complex stacks (like WordPress, Open edX, Nextcloud, secure intranets, etc.) by defining it as a dependency in your deployment configurations.

## Lifecycle Management with LibScript

You can easily install, uninstall, start, stop, and package OpenVPN using the LibScript CLI:

### Installation
**Unix (Linux/macOS):**
```sh
./cli.sh install openvpn [VERSION] [OPTIONS]
# Or via global manager:
libscript install openvpn
```
**Windows:**
```cmd
cli.cmd install openvpn [VERSION] [OPTIONS]
```

### Start & Stop
```sh
./cli.sh start openvpn
./cli.sh stop openvpn
```

### Uninstallation
```sh
./cli.sh uninstall openvpn
```

### Packaging
LibScript can package this component into various deployment formats:
```sh
libscript package_as docker openvpn
libscript package_as msi openvpn
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct installation script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.
