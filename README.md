deploy-sh
=========

Deployment scripts.

## History / roadmap:

  0. First version was written in [Python](https://en.wikipedia.org/wiki/Python_(programming_language)) (59+ repos with ["off" prefix](https://github.com/offscale?q=off&language=python)) for mostly [Linux](https://en.wikipedia.org/wiki/Linux) ([Ubuntu](https://en.wikipedia.org/wiki/Ubuntu)) with a bit of work for [Debian](https://en.wikipedia.org/wiki/Debian) support;
  1. Second version being written in [`/bin/sh`](https://en.wikipedia.org/wiki/Bourne_shell) [this repo] targetting [macOS](https://en.wikipedia.org/wiki/MacOS); [Linux](https://en.wikipedia.org/wiki/Linux); and a little bit of [PowerShell](https://en.wikipedia.org/wiki/PowerShell#Scripting) for modern [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows).
  2. Third version being written in [C](https://en.wikipedia.org/wiki/C_(programming_language)) [[C89](https://en.wikipedia.org/wiki/ANSI_C#C89)], targetting [SunOS](https://en.wikipedia.org/wiki/SunOS) / [illumos](https://en.wikipedia.org/wiki/Illumos), [*BSD](https://en.wikipedia.org/wiki/Comparison_of_BSD_operating_systems); [macOS](https://en.wikipedia.org/wiki/MacOS); [DOS](https://en.wikipedia.org/wiki/Comparison_of_DOS_operating_systems); [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows); [Linux](https://en.wikipedia.org/wiki/Linux); [OS/360](https://en.wikipedia.org/wiki/OS/360_and_successors); and [z/OS](https://en.wikipedia.org/wiki/Z/OS). [libacquire](https://github.com/offscale/libacquire) will become the base of this.

## Advantage

  - [Linux](https://en.wikipedia.org/wiki/Linux) variants are useful in [Docker](https://en.wikipedia.org/wiki/Docker_(software)), other image types [e.g., see [Packer](https://www.packer.io), [Unikernels](https://en.wikipedia.org/wiki/Unikernel)], and natively;
  - [macOS](https://en.wikipedia.org/wiki/MacOS) variant is useful for native usage;
  - [Windows](https://en.wikipedia.org/wiki/Microsoft_Windows)—coming soon—is useful for [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/about/), other image types, and natively.

## Usage

    ./install.sh

See [`conf.env.sh`](./conf.env.sh) for options that can be overriden by setting environment variables.

### Docker usage

For debugging, you might want to run something like:

    docker build --file debian.Dockerfile --progress='plain' --no-cache --tag "${PWD##*/}":debian .

<hr/>

## License

Licensed under either of:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be licensed as above, without any additional terms or conditions.
