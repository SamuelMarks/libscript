# Mdevd

Compatible daemonized mdev device manager.

## Purpose & Current State

This document provides context and technical details for the **Mdevd** component (part of the
`base-system` module) within the LibScript ecosystem. Mdevd is a small daemon implementing the same
interface as mdev while remaining resident to process kernel netlink events efficiently.

## Usage

You can install this component using the global `libscript` command.

**Unix (Linux/macOS):**

```sh
./libscript.sh install mdevd
```

**Windows:**

```cmd
libscript.cmd install mdevd
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
