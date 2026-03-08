# Busybox

## Purpose & Overview
This directory contains the installation and configuration scripts for **Busybox** within the LibScript ecosystem. Busybox is a software suite that provides several Unix utilities in a single executable file.

This module works both as a local version manager for Busybox (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager `libscript`. It allows LibScript to use Busybox as a core dependency to build bigger, more complex software stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage with LibScript

You can interact with Busybox using the `libscript` CLI. 

### Install
To install Busybox:
```sh
libscript install busybox [VERSION] [OPTIONS]
```

### Start / Stop
If applicable (for example, running an httpd server via Busybox):
```sh
libscript start busybox
libscript stop busybox
```

### Uninstall
To gracefully remove Busybox and clean up its binaries:
```sh
libscript uninstall busybox
```

### Package
To generate a deployment configuration or installer for a stack containing Busybox:
```sh
libscript package_as docker busybox
libscript package_as msi busybox
```
*(Supports packaging as docker, docker_compose, msi, innosetup, nsis, or TUI).*

## Variables

See `vars.schema.json` for details on available variables.
