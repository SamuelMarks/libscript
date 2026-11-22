# nodeenv

Bootstrap module for the `nodeenv` Node.js virtual environment manager.

## Usage

Provides `nodeenv` to allow creation of isolated Node.js virtual environments (compatible with
Python virtualenv). Open edX uses `nodeenv` during its frontend asset compilation pipeline to
isolate Node.js runtime execution.

```sh
./libscript.sh install nodeenv
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                              | Default  | Aliases/Examples |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `NODEENV_INSTALL_METHOD` | How to install nodeenv. 'libscript_native' uses pip/uv in isolated dir, 'system' uses system package manager or user python environment. | `system` |                  |
| `NODEENV_VERSION`        | Specific version of nodeenv to install (e.g. '1.9.1', 'latest').                                                                         | `latest` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
