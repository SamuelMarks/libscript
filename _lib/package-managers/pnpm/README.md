# Pnpm

Bootstrap module for the `pnpm` package manager.

## Usage

Ensures the `pnpm` executable is available by pulling in Node.js/npm and running
`npm install -g pnpm`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `pnpm` versions natively by default (`PNPM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages pnpm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/pnpm/<version>`.
