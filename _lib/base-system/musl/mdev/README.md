# Mdev

BusyBox dynamic device node manager.

## Purpose & Current State

This document provides context and technical details for the **Mdev** component (part of the
`base-system` module) within the LibScript ecosystem. Mdev is a miniature dynamic device node
manager implementing hotplug device initialization and event dispatching.

## Usage

You can install this component using the global `libscript` command.

**Unix (Linux/macOS):**

```sh
./libscript.sh install mdev
```

**Windows:**

```cmd
libscript.cmd install mdev
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
