# Package Managers

## Usage

This folder describes the **Bootstrap** components within the LibScript ecosystem. It contains
installers and initializers for various fundamental package managers and shell environments.

The bootstrap components function both as **local version managers** (similar to rvm, nvm, pyenv,
uv) for their respective tools and can be invoked seamlessly from the **global version manager**,
`libscript`. Because of this flexible architecture, the bootstrap utilities can be used by
`libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by
ensuring the underlying host environment is correctly provisioned.

## Supported Bootstrap Managers

Currently supported tools in this folder include:

- `apk`: Alpine Linux package manager
- `brew`: Homebrew package manager
- `scoop`: Windows command-line installer
- `winget`: Windows Package Manager

_(Note: Additional components like PowerShell also exist within subdirectories)._

You can install, start, stop, package, and uninstall package-managers using the global `libscript`
command or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install package-managers

./cli.sh install package-managers

./libscript.sh start package-managers
./cli.sh start package-managers

./libscript.sh stop package-managers
./cli.sh stop package-managers

./libscript.sh package_as docker package-managers
./cli.sh package_as docker package-managers

./libscript.sh uninstall package-managers
./cli.sh uninstall package-managers
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install package-managers

:: Local CLI
cli.cmd install package-managers

:: Start and Stop
libscript.cmd start package-managers
cli.cmd start package-managers

libscript.cmd stop package-managers
cli.cmd stop package-managers

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi package-managers
cli.cmd package_as msi package-managers

:: Uninstall
libscript.cmd uninstall package-managers
cli.cmd uninstall package-managers
```

## Platform Support

- Linux
- macOS
- Windows

## Available Components

<!-- BEGIN_COMPONENTS -->

- [ansible-galaxy](./ansible-galaxy/README.md)
- [apk](./apk/README.md)
- [apt](./apt/README.md)
- [aqua](./aqua/README.md)
- [asdf](./asdf/README.md)
- [awscli](./awscli/README.md)
- [azure-cli](./azure-cli/README.md)
- [brew](./brew/README.md)
- [bun-pm](./bun-pm/README.md)
- [bundler](./bundler/README.md)
- [cabal](./cabal/README.md)
- [cargo](./cargo/README.md)
- [cargo-binstall](./cargo-binstall/README.md)
- [choco](./choco/README.md)
- [composer](./composer/README.md)
- [conan](./conan/README.md)
- [conda](./conda/README.md)
- [cpanm](./cpanm/README.md)
- [cygwin](./cygwin/README.md)
- [deno-pm](./deno-pm/README.md)
- [dnf](./dnf/README.md)
- [emerge](./emerge/README.md)
- [eopkg](./eopkg/README.md)
- [flatpak](./flatpak/README.md)
- [fnm](./fnm/README.md)
- [gem](./gem/README.md)
- [ghcup](./ghcup/README.md)
- [go-pm](./go-pm/README.md)
- [google-cloud-sdk](./google-cloud-sdk/README.md)
- [guix](./guix/README.md)
- [hatch](./hatch/README.md)
- [helm](./helm/README.md)
- [julia](./julia/README.md)
- [krew](./krew/README.md)
- [luarocks](./luarocks/README.md)
- [macports](./macports/README.md)
- [mamba](./mamba/README.md)
- [mas](./mas/README.md)
- [mise](./mise/README.md)
- [mix](./mix/README.md)
- [msys2](./msys2/README.md)
- [nimble](./nimble/README.md)
- [nix](./nix/README.md)
- [npm](./npm/README.md)
- [nuget](./nuget/README.md)
- [nvm](./nvm/README.md)
- [opam](./opam/README.md)
- [pacman](./pacman/README.md)
- [paru](./paru/README.md)
- [pdm](./pdm/README.md)
- [pip](./pip/README.md)
- [pipx](./pipx/README.md)
- [pkg](./pkg/README.md)
- [pkgx](./pkgx/README.md)
- [pnpm](./pnpm/README.md)
- [poetry](./poetry/README.md)
- [pub](./pub/README.md)
- [pyenv](./pyenv/README.md)
- [r](./r/README.md)
- [rbenv](./rbenv/README.md)
- [rebar3](./rebar3/README.md)
- [rustup](./rustup/README.md)
- [rvm](./rvm/README.md)
- [rye](./rye/README.md)
- [sbt](./sbt/README.md)
- [scoop](./scoop/README.md)
- [sdkman](./sdkman/README.md)
- [snap](./snap/README.md)
- [spack](./spack/README.md)
- [stack](./stack/README.md)
- [swupd](./swupd/README.md)
- [uv](./uv/README.md)
- [vcpkg](./vcpkg/README.md)
- [winget](./winget/README.md)
- [xbps](./xbps/README.md)
- [yarn](./yarn/README.md)
- [yay](./yay/README.md)
- [zypper](./zypper/README.md)

<!-- END_COMPONENTS -->
