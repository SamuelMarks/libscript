# Build Systems, Cross-Compilers, SDKs & Compiler Fuzzers (`_lib/toolchains/`)

## Overview

**Tier Scope**: `T1 / T2`

Build systems (`cmake`, `ninja`, `meson`, `bazel`, `buck2`, `make`), LFS/musl/bare-metal/ReactOS/DOS
cross-toolchains (`bootstrap`, `lfs-toolchain`, `arm-none-eabi-gcc`, `riscv-none-elf-gcc`,
`zephyr-sdk`, `rosbe`, `openwatcom`, `msvc`), and verification tools (`shellcheck`, `csmith`,
`yarpgen`, `wix`).

Each subdirectory in `_lib/toolchains/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/toolchains/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh android-sdk --help
./libscript.sh install android-sdk latest
./_lib/toolchains/android-sdk/cli.sh test
```

```cmd
.\libscript.cmd android-sdk --help
.\libscript.cmd install android-sdk latest
.\_lib\toolchains\android-sdk\cli.cmd test
```

## Components (60)

<!-- BEGIN_COMPONENTS -->

- [`android-sdk`](./android-sdk/README.md) (`T1` — `userland-package`): Google Android SDK
  command-line tools (sdkmanager), platform-tools, platforms, and build-tools for Android and Kotlin
  Multiplatform builds.
- [`arm-none-eabi-gcc`](./arm-none-eabi-gcc/README.md) (`T1` — `userland-package`,
  `cross-toolchain`): Bare-metal ARM Cortex-M/Cortex-R GNU embedded C/C++ cross-toolchain
  (arm-none-eabi-gcc, objcopy, gdb, newlib, picolibc).
- [`auto-win-msvc`](./auto-win-msvc/README.md) (`T1` — `userland-package`): 91-module C89
  POSIX/BSD/Linux/Solaris/macOS compatibility header and static library layer for MSVC and
  OpenWatcom.
- [`autoconf`](./autoconf/README.md) (`T1` — `userland-package`): Extensible M4 macro package
  producing portable POSIX configure scripts.
- [`automake`](./automake/README.md) (`T1` — `userland-package`): Tool for automatically generating
  GNU Standards-compliant Makefile.in files.
- [`bazel`](./bazel/README.md) (`T1` — `userland-package`): A fast, scalable, multi-language and
  extensible build system, installed via Bazelisk.
- [`bear`](./bear/README.md) (`T1` — `userland-package`): Standalone version manager and installer
  for Build EAR (bear), generating Clang JSON compilation databases (compile_commands.json) for Make
  and Kbuild projects.
- [`bootstrap`](./bootstrap/README.md) (`T1` — `userland-package`): T1 Linux LFS multi-stage
  cross-toolchain bootstrapping
- [`buck2`](./buck2/README.md) (`T1` — `userland-package`): Fast, hermetic, multi-language
  large-scale build system from Meta.
- [`cargo-llvm-cov`](./cargo-llvm-cov/README.md) (`T1` — `userland-package`): Cargo subcommand for
  LLVM source-based line, region, and branch code coverage JSON extraction.
- [`catch2`](./catch2/README.md) (`T1` — `userland-package`): Standalone version manager and CMake
  multi-TU source builder for Catch2 (pinned default 3.7.1) with upstream CTest verification.
- [`ccache`](./ccache/README.md) (`T1` — `userland-package`): A fast C and C++ compiler cache.
- [`cdd-c`](./cdd-c/README.md) (`T1` — `userland-package`): Lossless C89 Concrete Syntax Tree (CST)
  parser and 4-pass lowering transformer (cdd-c-transform).
- [`cmake`](./cmake/README.md) (`T1` — `userland-package`): An open-source, cross-platform family of
  tools designed to build, test and package software.
- [`coursier`](./coursier/README.md) (`T1` — `userland-package`): A Scala artifact fetcher and tool
  launcher.
- [`csmith`](./csmith/README.md) (`T1` — `userland-package`): Standalone version manager and source
  builder for Csmith, generating UB-free random C programs and providing runtime checksum headers
  under CSMITH_HOME/include.
- [`doxygen`](./doxygen/README.md) (`T1` — `userland-package`): Doxygen documentation analyzer and
  XML symbol extractor for auditing C89 docstring coverage.
- [`dtc`](./dtc/README.md) (`T1` — `userland-package`): Device Tree Compiler (dtc) and libfdt
  utilities for compiling and overlaying Zephyr and embedded hardware Devicetrees.
- [`emscripten`](./emscripten/README.md) (`T1` — `userland-package`): LLVM-based C and C++ compiler
  toolchain targeting WebAssembly.
- [`fmt`](./fmt/README.md) (`T1` — `userland-package`): Standalone version manager and CMake source
  builder for {fmt} (pinned default 11.0.2), providing both single-TU fmt/format.cc template inputs
  and full multi-TU CTest verification.
- [`gcc-torture`](./gcc-torture/README.md) (`T1` — `userland-package`): Standalone version manager
  for the upstream GCC gcc.c-torture/execute C execution test corpus with DejaGnu .x and
  nested-function filter manifests.
- [`gcp-cli`](./gcp-cli/README.md) (`T1` — `userland-package`): Component for installing and
  managing the Google Cloud CLI (gcloud).
- [`gradle`](./gradle/README.md) (`T1` — `userland-package`): A build automation tool for
  multi-language software development, primarily Java.
- [`huggingface-cli`](./huggingface-cli/README.md) (`T1` — `userland-package`): Official Hugging
  Face Hub CLI (`huggingface-cli` / `hf`) for downloading models, datasets, and managing
  repositories.
- [`just`](./just/README.md) (`T1` — `userland-package`): A handy way to save and run
  project-specific commands.
- [`lcov`](./lcov/README.md) (`T1` — `userland-package`): Standalone version manager and installer
  for LCOV (lcov, geninfo, genhtml), extracting function, line, and branch gcov coverage metrics.
- [`lfs-toolchain`](./lfs-toolchain/README.md) (`T1` — `userland-package`): Linux From Scratch (LFS)
  Chapter 5 Stage 1 & 2 cross-compiler and binutils toolchain.
- [`libtool`](./libtool/README.md) (`T1` — `userland-package`): Generic shared library support
  script abstracting platform library conventions.
- [`libtpu-rs`](./libtpu-rs/README.md) (`T1` — `userland-package`): Clean-room Rust PJRT TPU
  runtime/compiler version manager, isolated JAX test environment, and SIGPLAN E0-E8 empirical
  evaluation harness.
- [`llvm`](./llvm/README.md) (`T1` — `userland-package`): Modular compiler infrastructure and
  backend toolchain utilities.
- [`make`](./make/README.md) (`T1` — `userland-package`): Standard build automation tool generating
  executables and targets from Makefiles.
- [`maven`](./maven/README.md) (`T1` — `userland-package`): A software project management and
  comprehension tool, primarily for Java.
- [`meson`](./meson/README.md) (`T1` — `userland-package`): The Meson high-productivity build
  system.
- [`msbuild`](./msbuild/README.md) (`T1` — `userland-package`): Microsoft Build Engine for .NET and
  Visual C++ project files.
- [`msitools`](./msitools/README.md) (`T1` — `userland-package`): GNOME msitools suite providing
  wixl, msiinfo, msibuild, msidump, and msiextract for MSI authoring baselines.
- [`msvc`](./msvc/README.md) (`T1` — `userland-package`): Microsoft Visual C++ (MSVC) Build Tools
  and Windows SDK compiler toolchain.
- [`nasm`](./nasm/README.md) (`T1` — `userland-package`): The Netwide Assembler portable x86 and
  x86-64 assembler.
- [`ninja`](./ninja/README.md) (`T1` — `userland-package`): A small build system with a focus on
  speed.
- [`openocd`](./openocd/README.md) (`T1` — `userland-package`): Open On-Chip Debugger providing
  SWD/JTAG hardware flashing and GDB remote server support for ARM, RISC-V, and Xtensa targets.
- [`openwatcom`](./openwatcom/README.md) (`T1` — `userland-package`): OpenWatcom v2 16/32-bit C/C++
  cross-compiler (wcl386, wlink, wstrip, DOS32A.EXE) targeting MS-DOS LE and Win32.
- [`pkgconfig`](./pkgconfig/README.md) (`T1` — `userland-package`): Compiler and linker metadata
  query tool for installed libraries.
- [`protobuf`](./protobuf/README.md) (`T1` — `userland-package`): Protocol Buffers data interchange
  compiler (protoc) and schema toolchain.
- [`qmake`](./qmake/README.md) (`T1` — `userland-package`): Cross-platform Makefile generator from
  the Qt framework.
- [`riscv-none-elf-gcc`](./riscv-none-elf-gcc/README.md) (`T1` — `userland-package`): Bare-metal
  32/64-bit RISC-V multilib (rv32imac/rv64imac) embedded GNU cross-toolchain with newlib and
  picolibc support.
- [`rosbe`](./rosbe/README.md) (`T1` — `userland-package`, `cross-toolchain`): Isolated ReactOS
  Build Environment cross-compilation toolchain providing i686-w64-mingw32 and x86_64-w64-mingw32
  GCC/binutils and host-tools integration alongside CMake and Ninja.
- [`sccache`](./sccache/README.md) (`T1` — `userland-package`): Shared compilation cache for C, C++,
  Rust, and CUDA.
- [`scons`](./scons/README.md) (`T1` — `userland-package`): Software construction tool configured
  with Python scripts.
- [`shellcheck`](./shellcheck/README.md) (`T1` — `userland-package`): A static analysis tool and
  linter for POSIX sh and shell scripts.
- [`swig`](./swig/README.md) (`T1` — `userland-package`): Simplified Wrapper and Interface Generator
  connecting C/C++ with high-level languages.
- [`texlive`](./texlive/README.md) (`T1` — `userland-package`): Reproducible scholarly LaTeX
  typesetting toolchain providing pdflatex and bibtex.
- [`vcpkg-tool`](./vcpkg-tool/README.md) (`T1` — `userland-package`): Native C++ command-line binary
  frontend for the vcpkg package manager.
- [`wasmtime`](./wasmtime/README.md) (`T1` — `userland-package`): A fast and secure runtime and CLI
  toolchain for WebAssembly.
- [`west`](./west/README.md) (`T1` — `userland-package`): Zephyr RTOS multi-repository manifest,
  build, flash, and debug meta-tool isolated in a component-managed virtual environment.
- [`win-cmd-rs`](./win-cmd-rs/README.md) (`T1` — `userland-package`): Safe Rust Windows cmd.exe
  interpreter (wincmd) and linear Packrat 50-rule linter / 4-pass CST rewriter (wincheck).
- [`wix`](./wix/README.md) (`T1` — `userland-package`): Cross-platform .NET 8 WiX v4/v5 CLI and
  Windows WiX v3.14 Toolset for building MSI installation packages.
- [`xmake`](./xmake/README.md) (`T1` — `userland-package`): A cross-platform Lua-based build
  utility.
- [`xpk`](./xpk/README.md) (`T1` — `userland-package`): Google Cloud Accelerated Processing Kit
  (xpk) for provisioning GKE TPU/GPU clusters and scheduling distributed AI/ML training and
  inference workloads.
- [`yarpgen`](./yarpgen/README.md) (`T1` — `userland-package`): Standalone version manager and
  source builder for YARPGen v2, generating deterministic UB-free C and C++17 differential checksum
  programs.
- [`yasm`](./yasm/README.md) (`T1` — `userland-package`): Modular BSD-licensed rewrite of the NASM
  x86/AMD64 assembler.
- [`zephyr-sdk`](./zephyr-sdk/README.md) (`T1` — `userland-package`, `cross-toolchain`): Official
  Zephyr RTOS cross-compilation SDK bundling bare-metal GCC/LLVM toolchains and host utilities
  across Linux, macOS, and Windows.

<!-- END_COMPONENTS -->
