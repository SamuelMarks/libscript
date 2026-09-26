# Eudev (Musl)

Eudev device manager compiled against musl libc.

## Purpose & Current State

This document provides context and technical details for the **Eudev (Musl)** component (part of the
`base-system` module) within the LibScript ecosystem. Eudev is a standalone, systemd-independent
fork of udev managing hardware device nodes dynamically.

## Usage

You can install this component using the global `libscript` command.

**Unix (Linux/macOS):**

```sh
./libscript.sh install eudev-musl
```

**Windows:**

```cmd
libscript.cmd install eudev-musl
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
