libscript
=========

[Cross-platform](https://en.wikipedia.org/wiki/Cross-platform_software)—[`/bin/sh`](https://en.wikipedia.org/wiki/Bourne_shell); [`cmd.exe`](https://en.wikipedia.org/wiki/Cmd.exe)—[scripts library](https://en.wikipedia.org/wiki/Library_(computing)) for: [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows); [Linux](https://en.wikipedia.org/wiki/Linux); [macOS](https://en.wikipedia.org/wiki/MacOS); [FreeBSD](https://en.wikipedia.org/wiki/FreeBSD); [SunOS](https://en.wikipedia.org/wiki/SunOS); &etc.

See also libscript's: [WHY.md](WHY.md); and [ROADMAP.md](ROADMAP.md).

## Features

[OS](https://en.wikipedia.org/wiki/Operating_system) support for:

  - [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows)
  - [Linux](https://en.wikipedia.org/wiki/Linux) ([Debian](https://en.wikipedia.org/wiki/Debian), [Alpine](https://en.wikipedia.org/wiki/Alpine_Linux), &etc.); inside/outside of [Docker](https://en.wikipedia.org/wiki/Docker_(software))
  - [macOS](https://en.wikipedia.org/wiki/MacOS)
  - [coming soon!] [*BSDs](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems) [[NetBSD](https://en.wikipedia.org/wiki/NetBSD), [FreeBSD](https://en.wikipedia.org/wiki/FreeBSD), [OpenBSD](https://en.wikipedia.org/wiki/OpenBSD)]
  - [coming soon!] [SunOS](https://en.wikipedia.org/wiki/SunOS) and derivatives | [forks](https://en.wikipedia.org/wiki/Fork_(software_development)) such as [illumos](https://en.wikipedia.org/wiki/Illumos)
  - [coming soon!] Other [UNIX](https://en.wikipedia.org/wiki/Unix)'s like: [IBM's z/OS](https://en.wikipedia.org/wiki/Z/OS); and [HP's Unix (HP/UX)](https://en.wikipedia.org/wiki/HP-UX).

Relocatable; no need to [`cd`](https://en.wikipedia.org/wiki/Cd_(command)) into the scripts [directory](https://en.wikipedia.org/wiki/Directory_(computing)).

Library [directory structure](https://en.wikipedia.org/wiki/Path_(computing)) is super-readable and [modular](https://en.wikipedia.org/wiki/Modular_programming).

Plenty of [guards](https://en.wikipedia.org/wiki/Include_guard) everywhere—[idempotency style](https://en.wikipedia.org/wiki/Idempotence#Computer_science_meaning)—so scripts can be interdependent—and [rerun](https://en.wikipedia.org/wiki/Pure_function)—without worry.

[**Dockerfiles**](https://en.wikipedia.org/wiki/Docker_(software)#Dockerfile_(example)) are generated. These are well optimised for Docker's cache mechanism.

Example of generated files are found in the [`gen`](./gen) directory.

## Current ‘installables’

### Toolchains

   | Name                          | Parameters        |
   |-------------------------------|-------------------|
   | [Node.js](https://nodejs.org) | `NODEJS_VERSION`* |
   | [Python](https://python.org)  | `PYTHON_VERSION`* |
   | [Rust](https://rust-lang.org) | `RUST_VERSION`*   |

* required

### Databases / storage layers

   | Name                                     | Parameters                                                                                                                |
   |------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
   | [PostgreSQL](https://postgresql.org)     | `POSTGRESQL_VERSION`†; `POSTGRES_USER`†; `POSTGRES_PASSWORD`‡; `POSTGRES_PASSWORD_FILE`‡; `POSTGRES_HOST`; `POSTGRES_DB`† |
   | [Valkey](https://valkey.io) [Redis fork] |                                                                                                                           |

  - † required
  - ‡ needs one-and-only-one

### Servers


   | Name                       | Parameters |
   |----------------------------|------------|
   | [nginx](https://nginx.org) | `VARS`‡    |

  - ‡`VARS`—if provided—must include `SERVER_NAME` and: `NGINX_FRAGMENT_CONF`; xor `WWWROOT` with optional `WWWROOT_AUTOINDEX`; xor `PROXY_PASS` with optional `PROXY_WEBSOCKETS`. 

## History / roadmap:

  0. First version was written in [Python](https://en.wikipedia.org/wiki/Python_(programming_language)) (59+ [repos](https://en.wikipedia.org/wiki/Software_repository) with ["off" prefix](https://github.com/offscale?q=off&language=python)) for mostly [Linux](https://en.wikipedia.org/wiki/Linux) ([Ubuntu](https://en.wikipedia.org/wiki/Ubuntu)) with a bit of work for [Debian](https://en.wikipedia.org/wiki/Debian) support;
  1. Second version being written in [`/bin/sh`](https://en.wikipedia.org/wiki/Bourne_shell) [this repo] targeting [macOS](https://en.wikipedia.org/wiki/MacOS); [Linux](https://en.wikipedia.org/wiki/Linux) ([.deb](https://en.wikipedia.org/wiki/Deb_(file_format)), [.rpm](https://en.wikipedia.org/wiki/RPM_Package_Manager), [.apk (Alpine Linux)](https://en.wikipedia.org/wiki/Alpine_Linux) distributions); [SunOS](https://en.wikipedia.org/wiki/SunOS); [*BSDs](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems); and [`cmd.exe`](https://en.wikipedia.org/wiki/Cmd.exe) for [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows);
  2. Third version being written in [C](https://en.wikipedia.org/wiki/C_(programming_language)) [[C89](https://en.wikipedia.org/wiki/ANSI_C#C89)], targeting all the above + [DOS](https://en.wikipedia.org/wiki/Comparison_of_DOS_operating_systems) and [OS/360](https://en.wikipedia.org/wiki/OS/360_and_successors). [libacquire](https://github.com/offscale/libacquire) will become the base of this.

## Advantage of this repo

  - [Linux](https://en.wikipedia.org/wiki/Linux) variants are useful in [Docker](https://en.wikipedia.org/wiki/Docker_(software)), other image types [e.g., see [Packer](https://www.packer.io), [Unikernels](https://en.wikipedia.org/wiki/Unikernel)], and natively;
  - [macOS](https://en.wikipedia.org/wiki/MacOS) variant is useful primarily natively;
  - [coming soon!] [*BSDs](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems) [[NetBSD](https://en.wikipedia.org/wiki/NetBSD), [FreeBSD](https://en.wikipedia.org/wiki/FreeBSD), [OpenBSD](https://en.wikipedia.org/wiki/OpenBSD)] are useful in jails or natively;
  - [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows) is useful for [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/about/), other image types, and natively;
  - [coming soon!] [SunOS](https://en.wikipedia.org/wiki/SunOS) / [illumos](https://en.wikipedia.org/wiki/Illumos) are useful for native usage on mainframes, both native and in virtualised / zones / container systems like [SmartOS](https://en.wikipedia.org/wiki/SmartOS);
  - [coming soon!] [IBM's z/OS](https://en.wikipedia.org/wiki/Z/OS) [coming soon!] useful in mainframes and for testing [OS/360](https://en.wikipedia.org/wiki/OS/360_and_successors) (from the 1960s); and
  - [coming soon!] [HP's Unix (HP/UX)](https://en.wikipedia.org/wiki/HP-UX) [coming soon!] (also specifically useful in mainframes).

Generally these [scripts](https://en.wikipedia.org/wiki/Scripting_language) are extremely portable and could be used to benchmark and security-audit any:

  - Platform virtualization software: https://en.wikipedia.org/wiki/Comparison_of_platform_virtualization_software
  - OS-level virtualization software: https://en.wikipedia.org/wiki/OS-level_virtualization#IMPLEMENTATIONS
  - μ-kernel: https://en.wikipedia.org/wiki/Microkernel
  - Unikernel: https://en.wikipedia.org/wiki/Unikernel
  - Any other kernel: https://en.wikipedia.org/wiki/Comparison_of_operating_system_kernels

## Advantage of C repo(s)

All the aforementioned advantages, plus:

  - [OS/360](https://en.wikipedia.org/wiki/OS/360_and_successors) useful natively (expected as a proof-of-concept only);
  - [DOS](https://en.wikipedia.org/wiki/Comparison_of_DOS_operating_systems) useful natively (expected as a proof-of-concept only).

## Usage

NOTE: You might want to manually set `LIBSCRIPT_DATA_DIR`; `LIBSCRIPT_BUILD_DIR`; and `LIBSCRIPT_TOOLS_DIR`.

Run from the same directory as this [README.md](README.md) file.
Alternatively, set `SCRIPT_NAME` to the correct `install.sh` location and run it anywhere.
```sh
$ # Replace `$(pwd)` if not in the 'libscript' directory.
$ export LIBSCRIPT_ROOT_DIR="$(pwd)"
$ # Disable all options (everything set to do-*not*-install)
$ . "${LIBSCRIPT_ROOT_DIR}"'/conf-no-all.env.sh'
$ # Enable installation of *just* Jupyter Hub
$ export JUPYTERHUB_INSTALL=1
$ # Set script location.
$ export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/install.sh'
$ . "${SCRIPT_NAME}"
```

See [`gen/env.sh`](./gen/env.sh) for options that can be overridden by setting environment variables.

## Usage (JSON)

To simplify usage, a JSON file format is provided. See [./install.json](./install.json) for an example.

## Usage (JSON) CLI

```sh
$ ./create_installer_from_json.sh -h
Create install scripts from JSON.

  -a whether to install all dependencies (required AND optional)
  -f filename
  -o output folder (defaults to ./tmp)
  -v verbosity (can be specified multiple times)
  -b base images for docker (space seperated, default: "alpine:latest debian:bookworm-slim")
  -h show help text
```

Which will create these files:

### `env.sh` ; `env.cmd`

Default environment. When nothing preexists in your env, this sets everything to install.

### `false_env.sh` ; `false_env.cmd`

False environment. This sets everything to *not* install.

### `install_gen.sh` ; `install_gen.cmd`

The actual installation script. Execute this like so:
```sh
$ # Set script location. Change from `pwd` if 'install_gen.sh' isn't in current dir.
$ export LIBSCRIPT_ROOT_DIR="$(pwd)"
$ export SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/install_gen.sh'
$ . "${SCRIPT_NAME}"
```

### `install_parallel_gen.sh`

Parallel version of the above installation script. Execute same way.

## Docker usage

For debugging, you might want to run something like:

```sh
$ distro='debian' # or 'alpine'
$ docker build --file "${distro}"'.Dockerfile' --progress='plain' --no-cache --tag "${PWD##*/}":"${distro}" .
```

### Docker builder

To make things more convenient, use this docker builder; setting `-i` to same as `-o` of `./create_installer_from_json.sh`:

```sh
$ ./create_docker_builder.sh -h
Create Docker image builder scripts.

-p prefix ($DOCKER_IMAGE_PREFIX, default: "deploysh")
-s suffix ($DOCKER_IMAGE_SUFFIX, default: "-latest")
-i input directory (`cd`s if provided, defaults to current working directory; adds scripts here also)
-v verbosity (can be specified multiple times)
-h show help text
```

#### Example

```sh
$ ./build_docker_images.sh -o ./tmp
$ cd ./tmp && sh ./docker_builder.sh
# or docker_builder_parallel.sh ^
```

<hr/>

## License

Licensed under any of:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)
- CC0 license ([LICENSE-CC0](LICENSE-CC0) or <https://creativecommons.org/publicdomain/zero/1.0/legalcode>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
