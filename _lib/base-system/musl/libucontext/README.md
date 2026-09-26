# libucontext

ucontext library replacement for musl libc.

## Purpose & Current State

This document provides context and technical details for the **libucontext** component (part of the
`base-system` module) within the LibScript ecosystem. libucontext provides implementations of
getcontext, setcontext, makecontext, and swapcontext functions absent from standard musl libc.

## Usage

You can install this component using the global `libscript` command.

**Unix (Linux/macOS):**

```sh
./libscript.sh install libucontext
```

**Windows:**

```cmd
libscript.cmd install libucontext
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
