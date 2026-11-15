# Microsoft Visual C++ Redistributable (`vcredist`)

Installs the Microsoft Visual C++ Redistributable (2015–2022) runtime libraries (`vcruntime140.dll`,
`msvcp140.dll`).

## Usage

```cmd
libscript.cmd install vcredist latest
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                    | Default  | Aliases/Examples |
| ------------------------- | -------------------------------------------------------------- | -------- | ---------------- |
| `VCREDIST_VERSION`        | Specific version of the Visual C++ Redistributable to install. | `latest` |                  |
| `VCREDIST_INSTALL_METHOD` | How to install VCREDIST ('libscript_native' or 'system').      | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
