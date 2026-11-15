# WiX Toolset

Windows Installer XML (WiX) Toolset (`candle.exe`, `light.exe`, `heat.exe`) for building `.msi`
packages.

## Usage

```cmd
libscript.cmd install wix 3.14
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                   | Default            | Aliases/Examples |
| -------------------- | --------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WIX_VERSION`        | Specific version of the WiX Toolset to install (e.g., 'latest', '5.0.2', '4.0.5', or '3.14'). | `5.0.2`            |                  |
| `WIX_INSTALL_METHOD` | How to install WIX ('libscript_native' via isolated dotnet tool / zip or 'system').           | `libscript_native` |                  |
| `WIX_DOWNLOAD_URL`   | Optional override URL for downloading WiX binary archive.                                     | ``                 |                  |
| `WIX_RELEASES_URL`   | Optional override URL for querying WiX release versions.                                      | ``                 |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
