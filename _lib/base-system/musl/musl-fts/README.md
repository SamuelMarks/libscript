# Musl FTS

FTS implementation shim for musl libc.

## Purpose & Current State

This document provides context and technical details for the **Musl FTS** component (part of the
`base-system` module) within the LibScript ecosystem. It provides the fts(3) family of tree
traversal functions (fts_open, fts_read, fts_children, fts_set, fts_close) for musl-based systems.

## Usage

You can install this component using the global `libscript` command.

**Unix (Linux/macOS):**

```sh
./libscript.sh install musl-fts
```

**Windows:**

```cmd
libscript.cmd install musl-fts
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
