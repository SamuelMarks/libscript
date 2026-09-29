# illumos

## Purpose & Overview

This directory houses the **illumos** components within the LibScript ecosystem, providing native
illumos distribution synthesis, ZFS pool management, SMF/init configurations, and packaging
integration.

## Usage

You can install and manage components in this category using the global `libscript` command:

```sh
./libscript.sh install illumos
```

Or on Windows:

```cmd
call libscript.cmd install illumos
```

## Platform Support

- SunOS / illumos (Native)
- Linux (Cross-synthesis / Proforma)
- macOS (Cross-synthesis / Proforma)
- Windows (Proforma Option A)

## Available Components

<!-- BEGIN_COMPONENTS -->

- `distro`: Complete illumos distribution synthesizer, packaging, and kernel loader configurations.

<!-- END_COMPONENTS -->
