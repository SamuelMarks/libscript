# LibScript Distribution Packagers

This directory provides universal from-scratch distribution packaging drivers:

- `build_apk.sh` / `build_apk.cmd`: Synthesizes Alpine-compatible APK binary packages (`.apk`).
- `build_deb.sh` / `build_deb.cmd`: Synthesizes Debian-compatible binary packages (`.deb`).
- `build_rpm.sh` / `build_rpm.cmd`: Synthesizes Red Hat-compatible binary packages (`.rpm`).
- `polyglot_package.sh` / `polyglot_package.cmd`: Multi-distribution packaging engine compiling once
  and emitting `.apk`, `.deb`, and `.rpm`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
