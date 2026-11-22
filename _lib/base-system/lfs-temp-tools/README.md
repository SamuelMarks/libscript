# LFS Temp Tools

Stage 2 Linux From Scratch (LFS) temporary cross-compiled tools orchestrator.

## Overview

Compiles and stages the foundational Stage 2 temporary tools (`m4`, `ncurses`, `bash`/`dash`,
`coreutils`/`busybox`, `diffutils`, `file`, `findutils`, `gawk`, `grep`, `gzip`, `make`, `patch`,
`sed`, `tar`, `xz`) inside the isolated LFS build workspace prior to chroot transition.

## Usage

```sh
./_lib/base-system/lfs-temp-tools/setup.sh [install|clean|status]
```

On Windows environments, native execution terminates with status 86 (`EX_UNAVAILABLE`) and defers to
container or Vagrant VM builders:

```cmd
call _lib\base-system\lfs-temp-tools\setup.cmd [install|clean|status]
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                       | Default            | Aliases/Examples |
| ------------------------------- | --------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LFS_TEMP_TOOLS_VERSION`        | Specific version of LFS Temporary Tools to build.                                 | `latest`           |                  |
| `LFS_TEMP_TOOLS_INSTALL_METHOD` | How to install LFS_TEMP_TOOLS. 'libscript_native' builds into the target sysroot. | `libscript_native` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
