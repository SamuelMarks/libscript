# GNU Coreutils

**Tier**: `T2` (`_lib/base-system/coreutils/`) | **Capabilities**: `sysroot-package`

Basic file, shell and text manipulation utilities

## Usage

```sh
./libscript.sh install coreutils
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                | Default  | Aliases/Examples |
| -------------------------- | ---------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `COREUTILS_VERSION`        | Specific version of coreutils to install.                                                                  | `latest` |                  |
| `COREUTILS_INSTALL_METHOD` | How to install COREUTILS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
