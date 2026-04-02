BusyBox
=======

## Purpose & Overview
This directory contains the installation and configuration scripts for **Busybox** within the LibScript ecosystem. Busybox is a software suite that provides several Unix utilities in a single executable file.

This module works both as a local version manager for Busybox (similar to `rvm`, `nvm`, `pyenv`, or `uv`) and can be seamlessly invoked from the global version manager `libscript`. It allows LibScript to use Busybox as a core dependency to build bigger, more complex software stacks (such as WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall busybox using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install busybox

./cli.sh install busybox

./libscript.sh start busybox
./cli.sh start busybox

./libscript.sh stop busybox
./cli.sh stop busybox

./libscript.sh package_as docker busybox
./cli.sh package_as docker busybox

./libscript.sh uninstall busybox
./cli.sh uninstall busybox
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install busybox

:: Local CLI
cli.cmd install busybox

:: Start and Stop
libscript.cmd start busybox
cli.cmd start busybox

libscript.cmd stop busybox
cli.cmd stop busybox

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi busybox
cli.cmd package_as msi busybox

:: Uninstall
libscript.cmd uninstall busybox
cli.cmd uninstall busybox
```

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
