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

| Variable                   | Description                                                                                                | Default  | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PACKAGERS_VERSION`        | Specific version of packagers to install.                                                                  | `latest` |                  |
| `PACKAGERS_INSTALL_METHOD` | How to install PACKAGERS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
