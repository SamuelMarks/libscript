# ReactOS Build Environment (`rosbe`)

Standalone LibScript cross-toolchain component provisioning the **ReactOS Build Environment
(`RosBE`)** with `i686-w64-mingw32` (`i386`) and `x86_64-w64-mingw32` (`amd64`) target support,
composing `_lib/toolchains/cmake` and `_lib/toolchains/ninja`.

## Usage

```sh
# Install isolated RosBE toolchain
./libscript.sh install rosbe 2.2.1

# Enable 64-bit x86_64-w64-mingw32 target support
./_lib/toolchains/rosbe/cli.sh target-add x86_64-w64-mingw32
```

## Configuration Variables

See [`vars.schema.json`](./vars.schema.json) for all supported configuration variables including
`ROSBE_VERSION`, `LIBSCRIPT_ROSBE_ARCH`, `LIBSCRIPT_ROSBE_URL`, and `LIBSCRIPT_ROSBE_INSTALL_DIR`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                             | Default            | Aliases/Examples |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ROSBE_INSTALL_METHOD`        | Installation strategy for rosbe ('libscript_native' provisions isolated RosBE directory, 'system' uses host MinGW-w64 + CMake + Ninja). | `libscript_native` |                  |
| `ROSBE_VERSION`               | Specific release version of ReactOS Build Environment to provision.                                                                     | `2.2.1`            | latest, 2.2.1    |
| `ROSBE_DOWNLOAD_URL`          | Override URL for downloading the prebuilt RosBE-Unix or RosBE-Windows archive.                                                          | `none`             |                  |
| `ROSBE_RELEASES_URL`          | Override URL for querying available upstream RosBE release versions.                                                                    | `none`             |                  |
| `LIBSCRIPT_ROSBE_VERSION`     | Override version of RosBE used during ReactOS source compilation.                                                                       | `2.2.1`            |                  |
| `LIBSCRIPT_ROSBE_ARCH`        | Active ReactOS target architecture exposed by RosBE ('i386' for 32-bit i686 or 'amd64' for 64-bit x86_64).                              | `i386`             |                  |
| `LIBSCRIPT_ROSBE_URL`         | Custom mirror URL for fetching the RosBE cross-compiler bundle.                                                                         | `none`             |                  |
| `LIBSCRIPT_ROSBE_INSTALL_DIR` | Custom destination directory for isolated RosBE toolchain installation.                                                                 | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
