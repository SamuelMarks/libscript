# OS, Ecosystem & Native Installer Package Managers (`_lib/package-managers/`)

## Overview

**Tier Scope**: `T1`

System, language-ecosystem, functional (`nix`, `guix`, `spack`), ReactOS (`rapps`), and Windows
(`winget`, `choco`, `scoop`, `msi-rs`) package manager bootstrappers and adapters.

Each subdirectory in `_lib/package-managers/` is an atomic, self-contained LibScript component
governed by its own `manifest.json` and `vars.schema.json`. Components in `_lib/package-managers/`
never cross-source sibling components directly; instead, they source `T0` helpers from
`engine/common/` and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5`
(`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh ansible-galaxy --help
./libscript.sh install ansible-galaxy latest
./_lib/package-managers/ansible-galaxy/cli.sh test
```

```cmd
.\libscript.cmd ansible-galaxy --help
.\libscript.cmd install ansible-galaxy latest
.\_lib\package-managers\ansible-galaxy\cli.cmd test
```

## Components (87)

<!-- BEGIN_COMPONENTS -->

- [`ansible-galaxy`](./ansible-galaxy/README.md) (`T1` — `userland-package`): Bootstrap module for
  the `ansible-galaxy` package manager.
- [`apk`](./apk/README.md) (`T1` — `userland-package`): This document describes the **apk** (Alpine
  Package Keeper) bootstrap component for the LibScript ecosystem. It handles the integration and
  management of the Alpine Linux package manager.
- [`apt`](./apt/README.md) (`T1` — `userland-package`): Bootstrap module for the `apt` package
  manager.
- [`aqua`](./aqua/README.md) (`T1` — `userland-package`): Bootstrap module for the `aqua` package
  manager.
- [`asdf`](./asdf/README.md) (`T1` — `userland-package`): Bootstrap module for the `asdf` universal
  version manager.
- [`awscli`](./awscli/README.md) (`T1` — `userland-package`): Bootstrap module for the `awscli`
  package manager.
- [`azure-cli`](./azure-cli/README.md) (`T1` — `userland-package`): Bootstrap module for the
  `azure-cli` package manager.
- [`brew`](./brew/README.md) (`T1` — `userland-package`): Homebrew is a free and open-source
  software package management system that simplifies the installation of software on macOS and
  Linux. It builds packages from source and provides pre-compiled binaries, making it easy to manage
  dependencies and development tools.
- [`bun-pm`](./bun-pm/README.md) (`T1` — `userland-package`): Fast all-in-one JavaScript runtime,
  bundler, transpiler, and package manager.
- [`bundler`](./bundler/README.md) (`T1` — `userland-package`): Bootstrap module for the `bundler`
  package manager.
- [`cabal`](./cabal/README.md) (`T1` — `userland-package`): Bootstrap module for `cabal` (Haskell
  package manager).
- [`cargo`](./cargo/README.md) (`T1` — `userland-package`): Bootstrap module for the `cargo` package
  manager.
- [`cargo-binstall`](./cargo-binstall/README.md) (`T1` — `userland-package`): Bootstrap module for
  the `cargo-binstall` package manager.
- [`choco`](./choco/README.md) (`T1` — `userland-package`): This document describes **Chocolatey
  (choco)**, a machine-level, command-line package manager and installer for Windows software.
- [`composer`](./composer/README.md) (`T1` — `userland-package`): Bootstrap module for the
  `composer` package manager.
- [`conan`](./conan/README.md) (`T1` — `userland-package`): Bootstrap module for `conan` (C/C++
  package manager).
- [`conda`](./conda/README.md) (`T1` — `userland-package`): Bootstrap module for the `conda` package
  manager via Miniconda.
- [`cpanm`](./cpanm/README.md) (`T1` — `userland-package`): Bootstrap module for `cpanm` (CPAN
  Minus - Perl).
- [`cygwin`](./cygwin/README.md) (`T1` — `userland-package`): Cygwin POSIX environment for Windows.
- [`deno-pm`](./deno-pm/README.md) (`T1` — `userland-package`): Bootstrap script for
  [Deno](https://deno.land), a modern and secure runtime for JavaScript and TypeScript that uses V8
  and is built in Rust.
- [`dnf`](./dnf/README.md) (`T1` — `userland-package`): Bootstrap module for the `dnf` package
  manager.
- [`emerge`](./emerge/README.md) (`T1` — `userland-package`): Bootstrap module for the Gentoo
  `emerge` package manager.
- [`eopkg`](./eopkg/README.md) (`T1` — `userland-package`): Bootstrap script for `eopkg`, the system
  package manager for Solus OS.
- [`flatpak`](./flatpak/README.md) (`T1` — `userland-package`): Bootstrap module for the `flatpak`
  package manager/tool.
- [`fnm`](./fnm/README.md) (`T1` — `userland-package`): Bootstrap script for
  [fnm](https://github.com/Schniz/fnm), a fast and simple Node.js version manager.
- [`gem`](./gem/README.md) (`T1` — `userland-package`): Bootstrap module for the `gem` package
  manager.
- [`ghcup`](./ghcup/README.md) (`T1` — `userland-package`): Bootstrap script for
  [GHCup](https://www.haskell.org/ghcup/), the main installer for the Haskell language toolchain
  (including `cabal` and `stack`).
- [`go-pm`](./go-pm/README.md) (`T1` — `userland-package`): Bootstrap module for the `go` package
  manager (enables `go install`).
- [`google-cloud-sdk`](./google-cloud-sdk/README.md) (`T1` — `userland-package`): Bootstrap module
  for the `google-cloud-sdk` package manager.
- [`guix`](./guix/README.md) (`T1` — `userland-package`): Bootstrap module for the `guix` (GNU Guix)
  package manager.
- [`hatch`](./hatch/README.md) (`T1` — `userland-package`): Bootstrap module for `hatch` (Modern
  Python project manager).
- [`helm`](./helm/README.md) (`T1` — `userland-package`): Bootstrap module for the `helm` Kubernetes
  package manager.
- [`julia`](./julia/README.md) (`T1` — `userland-package`): Bootstrap module for the `julia` package
  manager.
- [`krew`](./krew/README.md) (`T1` — `userland-package`): Bootstrap script for
  [Krew](https://krew.sigs.k8s.io/), the plugin manager for `kubectl` command-line tool.
- [`luarocks`](./luarocks/README.md) (`T1` — `userland-package`): Bootstrap script for
  [LuaRocks](https://luarocks.org/), the package manager for Lua modules.
- [`macports`](./macports/README.md) (`T1` — `userland-package`): Bootstrap module for the
  `macports` package manager/tool.
- [`mamba`](./mamba/README.md) (`T1` — `userland-package`): Bootstrap module for the `mamba` package
  manager.
- [`mas`](./mas/README.md) (`T1` — `userland-package`): Bootstrap module for the `mas` package
  manager (Mac App Store command line interface).
- [`maven-wrapper`](./maven-wrapper/README.md) (`T1` — `userland-package`): Apache Maven Wrapper
  (mvnw) standalone distribution manager for reproducible JVM project builds.
- [`mise`](./mise/README.md) (`T1` — `userland-package`): mise-en-place
- [`mix`](./mix/README.md) (`T1` — `userland-package`): Bootstrap module for `mix` (Elixir package
  manager and build tool).
- [`msi-rs`](./msi-rs/README.md) (`T1` — `userland-package`): Bootstrap module for the `msi-rs`
  package manager and WiX/msitools/msiexec replacement toolchain.
- [`msys2`](./msys2/README.md) (`T1` — `userland-package`): MSYS2 is a collection of tools and
  libraries providing an easy-to-use environment for building, installing, and running native
  Windows software. It consists of a command-line terminal called mintty, bash, version control
  systems like git, and various build systems like autotools and GCC.
- [`nimble`](./nimble/README.md) (`T1` — `userland-package`): Bootstrap script for
  [Nimble](https://github.com/nim-lang/nimble), the package manager for the Nim programming
  language. Typically installed via `choosenim`.
- [`nix`](./nix/README.md) (`T1` — `userland-package`): Nix is a powerful package manager for Linux
  and other Unix systems that makes package management reliable and reproducible. It provides atomic
  upgrades and rollbacks, side-by-side installation of multiple versions of a package, multi-user
  package management, and easy setup of build environments.
- [`nodeenv`](./nodeenv/README.md) (`T1` — `userland-package`): Bootstrap module for the nodeenv
  Node.js virtual environment manager.
- [`npm`](./npm/README.md) (`T1` — `userland-package`): Bootstrap module for the `npm` package
  manager.
- [`nuget`](./nuget/README.md) (`T1` — `userland-package`): Bootstrap module for the `nuget` package
  manager.
- [`nvm`](./nvm/README.md) (`T1` — `userland-package`): Bootstrap module for `nvm` (Node Version
  Manager).
- [`opam`](./opam/README.md) (`T1` — `userland-package`): Bootstrap script for
  [opam](https://opam.ocaml.org/), the source-based package manager for OCaml.
- [`pacman`](./pacman/README.md) (`T1` — `userland-package`): Bootstrap module for the `pacman`
  package manager.
- [`paru`](./paru/README.md) (`T1` — `userland-package`): Bootstrap module for the `paru` package
  manager.
- [`pdm`](./pdm/README.md) (`T1` — `userland-package`): Bootstrap module for `pdm` (Modern Python
  package and dependency manager).
- [`pip`](./pip/README.md) (`T1` — `userland-package`): Bootstrap module for the `pip` package
  manager.
- [`pipx`](./pipx/README.md) (`T1` — `userland-package`): Bootstrap module for the `pipx` package
  manager.
- [`pkg`](./pkg/README.md) (`T1` — `userland-package`): Bootstrap module for the FreeBSD `pkg`
  package manager.
- [`pkgsrc`](./pkgsrc/README.md) (`T1` — `userland-package`): NetBSD pkgsrc portable cross-platform
  package management framework (pkgin / bmake).
- [`pkgx`](./pkgx/README.md) (`T1` — `userland-package`): pkgx
- [`pnpm`](./pnpm/README.md) (`T1` — `userland-package`): Fast, disk space efficient package manager
- [`poetry`](./poetry/README.md) (`T1` — `userland-package`): Bootstrap script for
  [Poetry](https://python-poetry.org/), a tool for Python dependency management and packaging.
  Requires Python 3 to be installed.
- [`porg`](./porg/README.md) (`T1` — `userland-package`): Package organizer with LD_PRELOAD logging
  for LFS
- [`port`](./port/README.md) (`T1` — `userland-package`): Unified wrapper recipe for BSD Ports and
  MacPorts (port) package management.
- [`pub`](./pub/README.md) (`T1` — `userland-package`): Bootstrap module for `pub` (Dart / Flutter
  package manager).
- [`pyenv`](./pyenv/README.md) (`T1` — `userland-package`): Bootstrap module for `pyenv` (Python
  Version Manager).
- [`r`](./r/README.md) (`T1` — `userland-package`): Bootstrap module for the `R` package manager.
- [`rapps`](./rapps/README.md) (`T1` — `userland-package`): ReactOS Applications Manager CLI wrapper
  and host-side rapps-db INI parser with SHA-256 verified offline installer prefetching.
- [`rbenv`](./rbenv/README.md) (`T1` — `userland-package`): Bootstrap module for the `rbenv` package
  manager.
- [`rebar3`](./rebar3/README.md) (`T1` — `userland-package`): Bootstrap module for the `rebar3`
  package manager.
- [`rustup`](./rustup/README.md) (`T1` — `userland-package`): Bootstrap module for `rustup` (Rust
  toolchain installer).
- [`rvm`](./rvm/README.md) (`T1` — `userland-package`): Bootstrap module for the `rvm` package
  manager.
- [`rye`](./rye/README.md) (`T1` — `userland-package`): Bootstrap module for the `rye` package
  manager.
- [`sbt`](./sbt/README.md) (`T1` — `userland-package`): Bootstrap module for the `sbt` package
  manager.
- [`scoop`](./scoop/README.md) (`T1` — `userland-package`): This document describes the **Scoop**
  bootstrap component within the LibScript ecosystem. Scoop is a command-line installer for Windows
  that eliminates permission popup windows and hides GUI wizard dialogs.
- [`sdkman`](./sdkman/README.md) (`T1` — `userland-package`): Bootstrap script for
  [SDKMAN!](https://sdkman.io/), a tool for managing parallel versions of multiple Software
  Development Kits on most Unix based systems.
- [`snap`](./snap/README.md) (`T1` — `userland-package`): Bootstrap module for the `snap` package
  manager/tool.
- [`spack`](./spack/README.md) (`T1` — `userland-package`): Bootstrap script for
  [Spack](https://spack.io/), a flexible package manager that supports multiple versions,
  configurations, platforms, and compilers.
- [`stack`](./stack/README.md) (`T1` — `userland-package`): Bootstrap module for the `stack` package
  manager.
- [`swupd`](./swupd/README.md) (`T1` — `userland-package`): Bootstrap module for `swupd` (Clear
  Linux OS package manager).
- [`uv`](./uv/README.md) (`T1` — `userland-package`): Bootstrap module for the `uv` package manager
  (astral.sh).
- [`vcpkg`](./vcpkg/README.md) (`T1` — `userland-package`): Bootstrap module for the `vcpkg` package
  manager/tool.
- [`vfox`](./vfox/README.md) (`T1` — `userland-package`): Version Fox
- [`winget`](./winget/README.md) (`T1` — `userland-package`): This document describes **Winget**,
  the official Windows Package Manager CLI that allows users to discover, install, upgrade, remove,
  and configure applications on Windows 10 and Windows 11 computers.
- [`xbps`](./xbps/README.md) (`T1` — `userland-package`): Bootstrap module for the Void Linux `xbps`
  package manager.
- [`yarn`](./yarn/README.md) (`T1` — `userland-package`): Bootstrap module for the `yarn` package
  manager.
- [`yay`](./yay/README.md) (`T1` — `userland-package`): Bootstrap module for the `yay` package
  manager.
- [`yum`](./yum/README.md) (`T1` — `userland-package`): Legacy RHEL/CentOS Yellowdog Updater
  Modified (yum) RPM package manager wrapper.
- [`zypper`](./zypper/README.md) (`T1` — `userland-package`): Bootstrap module for the `zypper`
  package manager.

<!-- END_COMPONENTS -->
