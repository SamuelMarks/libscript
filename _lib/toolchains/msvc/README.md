# MSVC Build Tools

Microsoft Visual C++ (MSVC) Build Tools and Windows SDK compiler toolchain (`cl.exe`, `link.exe`,
`nmake.exe`).

## Usage

```cmd
libscript.cmd install msvc latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                               | Default  | Aliases/Examples |
| ---------------------- | ----------------------------------------------------------------------------------------- | -------- | ---------------- |
| `MSVC_VERSION`         | Specific version of MSVC Build Tools to install (e.g., '2022', '2026', or 'latest').      | `latest` |                  |
| `MSVC_INSTALL_METHOD`  | How to install MSVC ('libscript_native' or 'system').                                     | `system` |                  |
| `MSVC_ARCH`            | Target CPU architecture configured for cl.exe and dumpbin.exe ('x64', 'x86', or 'arm64'). | `x64`    |                  |
| `MSVC_CRT`             | MSVC C Runtime linkage flag ('MT' for static CRT or 'MD' for dynamic CRT).                | `MD`     |                  |
| `MSVC_DARICE_CUB_PATH` | Filesystem path to Microsoft Windows SDK darice.cub 105-ICE validation oracle table.      | ``       |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
