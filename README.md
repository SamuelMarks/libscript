deploy-sh
=========

Deployment scripts.

## History / roadmap:

  0. First version was written in [Python](https://en.wikipedia.org/wiki/Python_(programming_language)) (59+ repos with ["off" prefix](https://github.com/offscale?q=off&language=python)) for mostly [Linux](https://en.wikipedia.org/wiki/Linux) ([Ubuntu](https://en.wikipedia.org/wiki/Ubuntu)) with a bit of work for [Debian](https://en.wikipedia.org/wiki/Debian) support;
  1. Second version being written in [`/bin/sh`](https://en.wikipedia.org/wiki/Bourne_shell) [this repo] targetting [macOS](https://en.wikipedia.org/wiki/MacOS); [Linux](https://en.wikipedia.org/wiki/Linux) ([.deb](https://en.wikipedia.org/wiki/Deb_(file_format)), [.rpm](https://en.wikipedia.org/wiki/RPM_Package_Manager), and [.apk (Alpine Linux)](https://en.wikipedia.org/wiki/Alpine_Linux) distributions); and a little bit of [PowerShell](https://en.wikipedia.org/wiki/PowerShell#Scripting) for modern [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows);
  2. Third version being written in [C](https://en.wikipedia.org/wiki/C_(programming_language)) [[C89](https://en.wikipedia.org/wiki/ANSI_C#C89)], targetting [SunOS](https://en.wikipedia.org/wiki/SunOS) / [illumos](https://en.wikipedia.org/wiki/Illumos) based distributions; [*BSD](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems); [macOS](https://en.wikipedia.org/wiki/MacOS); [DOS](https://en.wikipedia.org/wiki/Comparison_of_DOS_operating_systems); [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows); [Linux](https://en.wikipedia.org/wiki/Linux); [OS/360](https://en.wikipedia.org/wiki/OS/360_and_successors); and [z/OS](https://en.wikipedia.org/wiki/Z/OS). [libacquire](https://github.com/offscale/libacquire) will become the base of this.

## Advantage of this repo

  - [Linux](https://en.wikipedia.org/wiki/Linux) variants are useful in [Docker](https://en.wikipedia.org/wiki/Docker_(software)), other image types [e.g., see [Packer](https://www.packer.io), [Unikernels](https://en.wikipedia.org/wiki/Unikernel)], and natively;
  - [macOS](https://en.wikipedia.org/wiki/MacOS) variant is useful for native usage;
  - [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows)—coming soon—is useful for [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/about/), other image types, and natively.

## Advantage of C repo(s)

All the aforementioned advantages, plus:

  - [SunOS](https://en.wikipedia.org/wiki/SunOS) / [illumos](https://en.wikipedia.org/wiki/Illumos) are useful for native usage on mainframes, both native and in virtualised / zones / container systems like [SmartOS](https://en.wikipedia.org/wiki/SmartOS);
  - [*BSD](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems) useful in jails, and natively;
  - [OS/360](https://en.wikipedia.org/wiki/OS/360_and_successors) useful natively (expected as a proof-of-concept only);
  - [DOS](https://en.wikipedia.org/wiki/Comparison_of_DOS_operating_systems) useful natively (expected as a proof-of-concept only);
  - [z/OS](https://en.wikipedia.org/wiki/Z/OS) for native mainframe deployment.

## Usage

Run from the same directory as this [README.md](README.md) file.
Alternatively, set `SCRIPT_NAME` to the correct `install.sh` location and run it anywhere.

    $ # Disable all options (so don't install anything)
    $ . ~/repos/deploy-sh/conf-no-all.env.sh
    $ # Enable installation of *just* Jupyter Notebook
    $ export JUPYTERHUB_INSTALL=1 
    $ # Set script location. Only use $(pwd) if its in your current working directory, otherwise specify.
    $ export SCRIPT_NAME="$(pwd)"'/install.sh'
    $ . "${SCRIPT_NAME}"

See [`conf.env.sh`](./conf.env.sh) for options that can be override by setting environment variables.

### Docker usage

For debugging, you might want to run something like:

    docker build --file debian.Dockerfile --progress='plain' --no-cache --tag "${PWD##*/}":debian .

<hr/>

## License

Licensed under any of:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)
- CC0 license ([LICENSE-CC0](LICENSE-CC0) or <https://creativecommons.org/publicdomain/zero/1.0/legalcode>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
