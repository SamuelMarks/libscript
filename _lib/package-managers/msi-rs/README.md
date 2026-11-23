# msi-rs

**Tier**: `T1` (`_lib/package-managers/msi-rs/`) | **Capabilities**: `userland-package`

Bootstrap module for the `msi-rs` package manager and Windows Installer (`.msi`) manipulation and
execution toolchain.

## Overview

`msi-rs` is a pure-Rust, cross-platform implementation of the Windows Installer technology stack. It
serves as a modern drop-in replacement for the WiX Toolset, `msitools`, and Microsoft's
`msiexec.exe` runtime across Windows, Linux, macOS, FreeBSD, and SunOS/Solaris.

The installer automates dependency resolution for the required C compiler toolchain and Rust/Cargo
environment, installs version-isolated binaries under `~/.libscript/msi-rs/<version>/bin`, and
manages active symlink aliases.

### Provided Binaries & Utilities

Installing `msi-rs` provides:

- **Installer CLI & Runtime:** `msi-cli`, `msi`
- **WiX Toolset Replacement Suite:** `candle`, `light`, `wix`, `dark`, `heat`, `lit`
- **MSI Inspection & Build Tools:** `msiinfo`, `msibuild`, `msidump`, `msiextract`

## Usage

Install and configure `msi-rs`:

```sh
# Install default/latest version
./libscript.sh install msi-rs latest

# Set default active version
./libscript.sh use msi-rs 0.0.1

# Run test suite
./libscript.sh test msi-rs

# Load into shell environment
. $(./libscript.sh env msi-rs latest)
```

On Windows Command Prompt:

```cmd
:: Install msi-rs
libscript.cmd install msi-rs latest

:: Run component test
libscript.cmd test msi-rs
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                            | Default                                 | Aliases/Examples |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------- | ---------------- |
| `MSI_RS_INSTALL_METHOD` | How to install msi-rs. 'libscript_native' builds and isolates version dirs, 'cargo' installs via cargo, or 'system' defers to system package managers. | `libscript_native`                      |                  |
| `MSI_RS_VERSION`        | Specific version or release tag of msi-rs to install.                                                                                                  | `v0.0.1`                                |                  |
| `MSI_RS_REPO_URL`       | Upstream source Git repository URL for msi-rs.                                                                                                         | `https://github.com/SamuelMarks/msi-rs` |                  |
| `MSI_RS_DOWNLOAD_URL`   | Direct download URL for prebuilt binary archive if available.                                                                                          | `none`                                  |                  |
| `MSI_RS_RELEASES_URL`   | Override URL for querying msi-rs available remote releases.                                                                                            | `none`                                  |                  |
| `MSI_RS_COMPONENTS`     | Comma-separated list of T1 components preloaded into live installer media or installed onto the target disk.                                           | `none`                                  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->

## Testing

Testing is strictly restricted to isolated Vagrant virtual machines across
`{macOS, Windows, FreeBSD, SunOS, Linux}`.

```sh
# Run multi-platform Vagrant verification
./tests/test_msi_rs_vagrant.sh --all

# Or on Windows Command Prompt:
.\tests\test_msi_rs_vagrant.cmd --all
```
