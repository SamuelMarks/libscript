# Programming Languages & C/C++ Compilers (`_lib/languages/`)

## Overview

**Tier Scope**: `T1`

Isolated native version managers (`O(1)` `${LIBSCRIPT_HOME}/bin` shims) for 35+ programming
languages and C/C++ compiler toolchains (`nodejs`, `python`, `rust`, `go`, `java`, `ruby`, `php`,
`zig`, `gcc`, `clang`, `tcc`, `edgcpp`, `custom-cc`, etc.).

Each subdirectory in `_lib/languages/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/languages/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh bun --help
./libscript.sh install bun latest
./_lib/languages/bun/cli.sh test
```

```cmd
.\libscript.cmd bun --help
.\libscript.cmd install bun latest
.\_lib\languages\bun\cli.cmd test
```

## Components (44)

<!-- BEGIN_COMPONENTS -->

- [`bun`](./bun/README.md) (`T1` — `userland-package`): A fast all-in-one JavaScript runtime,
  bundler, transpiler, and package manager.
- [`c`](./c/README.md) (`T1` — `userland-package`): Standard C compiler and toolchain (GCC/Clang).
- [`cc`](./cc/README.md) (`T1` — `userland-package`): Generic C compiler interface.
- [`clang`](./clang/README.md) (`T1` — `userland-package`, `cross-toolchain`): Standalone version
  manager and source builder for LLVM Clang.
- [`clojure`](./clojure/README.md) (`T1` — `userland-package`): Dynamic, functional Lisp dialect on
  the JVM with immutable data structures and concurrent programming primitives.
- [`cpp`](./cpp/README.md) (`T1` — `userland-package`): Standard C++ compiler and toolchain
  (G++/Clang++).
- [`crystal`](./crystal/README.md) (`T1` — `userland-package`): Statically type-checked compiled
  systems programming language with Ruby-inspired syntax.
- [`csharp`](./csharp/README.md) (`T1` — `userland-package`): C# compiler and .NET runtime.
- [`custom-cc`](./custom-cc/README.md) (`T1` — `userland-package`): Standalone version manager,
  source builder, and flag-normalizing telemetry wrapper for a custom C compiler.
- [`dart`](./dart/README.md) (`T1` — `userland-package`): Client-optimized language and SDK for fast
  multi-platform applications.
- [`deno`](./deno/README.md) (`T1` — `userland-package`): A secure runtime for JavaScript and
  TypeScript.
- [`edgcpp`](./edgcpp/README.md) (`T1` — `userland-package`): Standalone version manager,
  multi-flavor binary installer (edgcpp+llvm+gcc, edgcpp+llvm, edgcpp+gcc), source builder, and
  CC/CXX driver wrapper for the Edison Design Group C/C++ Front End (v7.0.2).
- [`elixir`](./elixir/README.md) (`T1` — `userland-package`): A dynamic, functional language for
  building scalable and maintainable applications.
- [`erlang`](./erlang/README.md) (`T1` — `userland-package`): Concurrent, fault-tolerant functional
  programming language and BEAM runtime environment.
- [`fortran`](./fortran/README.md) (`T1` — `userland-package`): GNU Fortran (gfortran) scientific
  and numerical array programming compiler.
- [`gcc`](./gcc/README.md) (`T1` — `userland-package`, `cross-toolchain`): Standalone version
  manager and source builder for the GNU C Compiler (GCC).
- [`gleam`](./gleam/README.md) (`T1` — `userland-package`): Friendly type-safe functional language
  for building scalable systems on BEAM and JavaScript.
- [`go`](./go/README.md) (`T1` — `userland-package`): An open-source programming language that makes
  it easy to build simple, reliable, and efficient software.
- [`groovy`](./groovy/README.md) (`T1` — `userland-package`): Multi-faceted dynamic and optionally
  typed programming language for the Java platform.
- [`haskell`](./haskell/README.md) (`T1` — `userland-package`): Glasgow Haskell Compiler (ghc)
  purely functional programming language toolchain.
- [`java`](./java/README.md) (`T1` — `userland-package`): Java Development Kit (JDK) and runtime
  environment.
- [`kotlin`](./kotlin/README.md) (`T1` — `userland-package`): A modern programming language that
  makes developers happier.
- [`lua`](./lua/README.md) (`T1` — `userland-package`): Lightweight, embeddable, fast scripting
  language interpreter and bytecode compiler.
- [`micropython`](./micropython/README.md) (`T1` — `userland-package`): Lean and efficient Python 3
  implementation for microcontrollers, Zephyr RTOS, FreeRTOS, and constrained edge systems.
- [`nim`](./nim/README.md) (`T1` — `userland-package`): Statically typed compiled systems
  programming language combining Pythonic expressiveness with C performance.
- [`nodejs`](./nodejs/README.md) (`T1` — `userland-package`): JavaScript runtime built on Chrome's
  V8 JavaScript engine.
- [`ocaml`](./ocaml/README.md) (`T1` — `userland-package`): Industrial-strength functional,
  imperative, and object-oriented programming language with static type inference.
- [`odin`](./odin/README.md) (`T1` — `userland-package`): Data-oriented systems programming language
  built for high performance, simplicity, and modern software development.
- [`perl`](./perl/README.md) (`T1` — `userland-package`): Highly capable, feature-rich
  general-purpose scripting and text-processing programming language.
- [`php`](./php/README.md) (`T1` — `userland-package`): A popular general-purpose scripting language
  that is especially suited to web development.
- [`prolog`](./prolog/README.md) (`T1` — `userland-package`): Comprehensive SWI-Prolog (swipl) logic
  programming environment and compiler.
- [`python`](./python/README.md) (`T1` — `userland-package`): A versatile programming language that
  lets you work quickly and integrate systems more effectively.
- [`racket`](./racket/README.md) (`T1` — `userland-package`): General-purpose, multi-paradigm
  Lisp/Scheme language platform for language-oriented programming.
- [`ruby`](./ruby/README.md) (`T1` — `userland-package`): A dynamic, open source programming
  language with a focus on simplicity and productivity.
- [`rust`](./rust/README.md) (`T1` — `userland-package`, `cross-toolchain`): A language empowering
  everyone to build reliable and efficient software.
- [`scala`](./scala/README.md) (`T1` — `userland-package`): Expressive statically typed JVM
  programming language seamlessly combining object-oriented and functional paradigms.
- [`scheme`](./scheme/README.md) (`T1` — `userland-package`): Chez Scheme and GNU Guile (scheme /
  guile) minimalist lexically scoped Lisp dialect.
- [`sh`](./sh/README.md) (`T1` — `userland-package`): POSIX-compliant shell environment.
- [`swift`](./swift/README.md) (`T1` — `userland-package`): A powerful and intuitive programming
  language for iOS, macOS, tvOS, and watchOS.
- [`tcc`](./tcc/README.md) (`T1` — `userland-package`): Standalone version manager and fast source
  builder for Fabrice Bellard's Tiny C Compiler (TCC).
- [`tcl`](./tcl/README.md) (`T1` — `userland-package`): Tool Command Language (tclsh) dynamic
  scripting interpreter and embeddable runtime.
- [`vala`](./vala/README.md) (`T1` — `userland-package`): Object-oriented programming language with
  a self-hosting compiler (valac) generating C code for GObject.
- [`vlang`](./vlang/README.md) (`T1` — `userland-package`): Simple, fast, safe, compiled systems
  programming language (v) with rapid C/native compilation.
- [`zig`](./zig/README.md) (`T1` — `userland-package`, `cross-toolchain`): A general-purpose
  programming language and toolchain for maintaining robust, optimal, and reusable software.

<!-- END_COMPONENTS -->
