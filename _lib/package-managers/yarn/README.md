# Yarn

Bootstrap module for the `yarn` package manager.

## Usage

Ensures the `yarn` executable is available by pulling in Node.js/npm and running
`npm install -g yarn`.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `yarn` versions natively by default (`YARN_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages yarn versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/yarn/<version>`.
