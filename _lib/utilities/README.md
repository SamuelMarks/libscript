# Cross-Platform CLI, Compression, Archive & Win32/DOS Utilities (`_lib/utilities/`)

## Overview

**Tier Scope**: `T1`

Core CLI tools, shells (`dash`, `powershell`, `busybox`, `toybox`), compression libraries,
benchmarking tools, and zero-emulation Windows PE / 32-bit MS-DOS (`dos32`) binary package managers
(`jq`, `gawk`, `7zip`, `curl`, `ripgrep`, `fzf`, `tmux`, `psmux`, etc.).

Each subdirectory in `_lib/utilities/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/utilities/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh 7zip --help
./libscript.sh install 7zip latest
./_lib/utilities/7zip/cli.sh test
```

```cmd
.\libscript.cmd 7zip --help
.\libscript.cmd install 7zip latest
.\_lib\utilities\7zip\cli.cmd test
```

## Components (46)

<!-- BEGIN_COMPONENTS -->

- [`7zip`](./7zip/README.md) (`T1` — `userland-package`): A highly efficient, open-source file
  archiver known for its high compression ratio.
- [`aria2`](./aria2/README.md) (`T1` — `userland-package`): A lightweight multi-protocol &
  multi-source command-line download utility.
- [`busybox`](./busybox/README.md) (`T1` — `userland-package`): Multi-call UNIX command suite
  combining common POSIX utilities with native Windows (MSVC) builds via
  SamuelMarks/busybox-windows.
- [`curl`](./curl/README.md) (`T1` — `userland-package`): A command-line tool and library for
  transferring data with URLs.
- [`dash`](./dash/README.md) (`T1` — `userland-package`): POSIX-compliant /bin/sh shell with native
  Windows (MSVC) and MS-DOS builds via SamuelMarks/dash-windows.
- [`exim`](./exim/README.md) (`T1` — `userland-package`, `service-daemon`): Exim mail transfer agent
  and local SMTP relay daemon.
- [`fd`](./fd/README.md) (`T1` — `userland-package`): Simple, fast, and user-friendly alternative to
  find written in Rust with gitignore awareness.
- [`ffmpeg`](./ffmpeg/README.md) (`T1` — `userland-package`): Complete cross-platform solution to
  record, convert, transcode, and stream audio and video.
- [`freebsd-usr-bin`](./freebsd-usr-bin/README.md) (`T1` — `userland-package`): FreeBSD usr.bin
  command-line utilities (~200 POSIX tools including sed, grep, cut, tr, sort, uniq, wc, head, tail,
  xargs, find, diff, patch, bmake) ported natively to Windows (MSVC) and MS-DOS (dos32).
- [`fzf`](./fzf/README.md) (`T1` — `userland-package`): General-purpose interactive command-line
  fuzzy finder written in Go.
- [`gawk`](./gawk/README.md) (`T1` — `userland-package`): Standalone GNU Awk 5.4+ pattern scanning
  and processing language with native Windows (MSVC) and MS-DOS (dos32) builds via
  SamuelMarks/gawk-windows.
- [`gettext`](./gettext/README.md) (`T1` — `userland-package`): Internationalization and
  localization utilities (msgfmt, xgettext, msginit, msgmerge) used by Open edX translation
  compilation.
- [`git`](./git/README.md) (`T1` — `userland-package`): Fast, scalable, distributed revision control
  system with cryptographic integrity.
- [`graphviz`](./graphviz/README.md) (`T1` — `userland-package`): Open-source graph visualization
  software and DOT layout CLI tools (dot, neato, fdp).
- [`hmailserver`](./hmailserver/README.md) (`T1` — `userland-package`, `service-daemon`): Free,
  open-source e-mail server for Microsoft Windows with SMTP relay support.
- [`htop`](./htop/README.md) (`T1` — `userland-package`): Cross-platform interactive ncurses system
  process viewer and resource monitor.
- [`hyperfine`](./hyperfine/README.md) (`T1` — `userland-package`): Command-line statistical
  benchmarking tool supporting warmup runs, prepare hooks, and JSON sample export.
- [`imagemagick`](./imagemagick/README.md) (`T1` — `userland-package`): Raster and vector digital
  image creation, editing, composition, and conversion CLI suite (magick).
- [`jq`](./jq/README.md) (`T1` — `userland-package`): Lightweight command-line JSON processor with
  native Windows (MSVC) and MS-DOS (dos32) builds via SamuelMarks/jq-windows.
- [`libarchive`](./libarchive/README.md) (`T1` — `userland-package`): Multi-format streaming archive
  library and bsdtar command-line utility.
- [`lynx`](./lynx/README.md) (`T1` — `userland-package`): Text-mode web browser and
  HTML-to-plaintext renderer used by Open edX bulk email and annotations.
- [`lz4`](./lz4/README.md) (`T1` — `userland-package`): Standalone version manager and
  custom-compiler source builder for LZ4 (pinned default 1.10.0) with upstream make check/test
  verification.
- [`memtier-benchmark`](./memtier-benchmark/README.md) (`T1` — `userland-package`): High-throughput
  NoSQL Redis and Memcached traffic generator recording P50, IQR, and P99 tail latencies.
- [`openssl`](./openssl/README.md) (`T1` — `userland-package`): Full-featured commercial-grade
  TLS/SSL cryptography library and openssl command-line toolkit.
- [`pandoc`](./pandoc/README.md) (`T1` — `userland-package`): Universal markup document converter
  supporting Markdown, LaTeX, HTML, DOCX, EPUB, and PDF.
- [`powershell`](./powershell/README.md) (`T1` — `userland-package`): A cross-platform task
  automation solution made up of a command-line shell, a scripting language, and a configuration
  management framework.
- [`psmux`](./psmux/README.md) (`T1` — `userland-package`): A native Windows terminal multiplexer,
  designed as a tmux alternative.
- [`ripgrep`](./ripgrep/README.md) (`T1` — `userland-package`): Line-oriented recursive regex search
  tool (rg) written in Rust respecting gitignore rules.
- [`rsync`](./rsync/README.md) (`T1` — `userland-package`): Fast incremental delta-transfer file
  synchronization and remote backup utility.
- [`sqlite-tools`](./sqlite-tools/README.md) (`T1` — `userland-package`): Official SQLite
  command-line bundle providing sqlite3 shell, sqldiff, and sqlite3_analyzer.
- [`tar`](./tar/README.md) (`T1` — `userland-package`): Tape archive creation, inspection, and
  extraction utility supporting POSIX ustar and pax formats.
- [`tmux`](./tmux/README.md) (`T1` — `userland-package`): tmux is a terminal multiplexer.
- [`tokei`](./tokei/README.md) (`T1` — `userland-package`): Fast, deterministic polyglot source line
  (SLOC) and file statistics auditor.
- [`toybox`](./toybox/README.md) (`T1` — `userland-package`): All-in-one BSD-licensed POSIX, Windows
  native (MSVC), and MS-DOS (dos32) command-line utility suite via SamuelMarks/toybox-windows.
- [`tree`](./tree/README.md) (`T1` — `userland-package`): Recursive depth-indented directory listing
  utility supporting colorized text, JSON, and XML output.
- [`unzip`](./unzip/README.md) (`T1` — `userland-package`): Portable Info-ZIP extraction and
  integrity testing utility for PKZIP (.zip) archives.
- [`vcredist`](./vcredist/README.md) (`T1` — `userland-package`): Microsoft Visual C++
  Redistributable runtime libraries (2015-2022 x64/x86).
- [`vim`](./vim/README.md) (`T1` — `userland-package`): Vi IMproved highly configurable modal text
  editor built for efficient code editing.
- [`wait4x`](./wait4x/README.md) (`T1` — `userland-package`): Wait4X is a command-line tool that
  allows you to wait for various services or conditions to become available before executing a
  command.
- [`wget`](./wget/README.md) (`T1` — `userland-package`): A free software package for retrieving
  files using HTTP, HTTPS, FTP and FTPS.
- [`xorriso`](./xorriso/README.md) (`T1` — `userland-package`): ISO-9660 and Rock Ridge filesystem
  image manipulation, El Torito bootable ISO creation, and burning tool.
- [`xz`](./xz/README.md) (`T1` — `userland-package`): General-purpose lossless data compression CLI
  and liblzma library utilizing the LZMA2 algorithm.
- [`yq`](./yq/README.md) (`T1` — `userland-package`): Portable command-line YAML, JSON, XML, CSV,
  and TOML processor using jq-like expression syntax.
- [`zip`](./zip/README.md) (`T1` — `userland-package`): Portable Info-ZIP compression and file
  packaging utility producing standard .zip archives.
- [`zlib`](./zlib/README.md) (`T1` — `userland-package`): Standalone version manager and
  custom-compiler source builder for zlib (pinned default 1.3.1) with upstream make test / CTest
  verification.
- [`zstd`](./zstd/README.md) (`T1` — `userland-package`): Fast real-time lossless compression
  algorithm and zstd CLI offering high compression ratios.

<!-- END_COMPONENTS -->
