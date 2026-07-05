# Zypper

Bootstrap module for the `zypper` package manager.

## Usage

This module ensures `zypper` is available and updated. Since `zypper` is natively integrated into
its corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `zypper` versions natively by default
(`ZYPPER_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting global
system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages zypper versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/zypper/<version>`.
