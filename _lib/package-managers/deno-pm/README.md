# Deno

**Tier**: `T1` (`_lib/package-managers/deno-pm/`) | **Capabilities**: `userland-package`

Bootstrap script for [Deno](https://deno.land), a modern and secure runtime for JavaScript and
TypeScript that uses V8 and is built in Rust.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                               | Default            | Aliases/Examples |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DENO_PM_INSTALL_METHOD` | Installation strategy for deno-pm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `DENO_PM_INSTALL`        | Path to the directory where Deno should be installed. Defaults to ~/.deno.                                                                                | `none`             |                  |
| `DENO_PM_VERSION`        | Specific version of deno to install.                                                                                                                      | `latest`           |                  |
| `DENO_PM_DOWNLOAD_URL`   | Override URL for downloading deno-pm binary or archive artifacts.                                                                                         | `none`             |                  |
| `DENO_PM_RELEASES_URL`   | Override URL for querying deno-pm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
