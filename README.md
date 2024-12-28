deploy-sh
=========

Deployment scripts.

History / roadmap:

  0. First version was written in Python (59+ repos with ["off" prefix](https://github.com/offscale?q=off&language=python));
  1. Second version being written in `/bin/sh` [this repo] targetting macOS; Linux; and a little bit of PowerShell for modern Windows.
  2. Third version being written in C [C89], targetting SunOS / illumos, *BSD; macOS; DOS; Windows; Linux; OS/360; and z/OS. [libacquire](https://github.com/offscale/libacquire) will become the base of this.

## Advantage

  - Linux variants are useful in Docker, other image types [e.g., see Packer, Unikernels], and natively;
  - macOS variant is useful for native usage;
  - Windows—coming soon—is useful for Windows Containers, other image types, and natively.

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
