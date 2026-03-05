# Developing LibScript

## Purpose
A contributor's guide to scaffolding, implementing, and verifying new cross-platform components within the LibScript ecosystem.

## What Makes Developing for LibScript Interesting?
You don't need to learn a complex DSL or a new programming language. If you can write a basic shell script, you can write a LibScript component. The framework abstracts away argument parsing, OS detection, help-text generation, and testing harnesses, letting you focus entirely on the core installation logic.

## Developing a Component
1. **Scaffold**: Create your directory (`_lib/_toolchain/my_tool`).
2. **Symlink Core Routers**: Link `cli.sh` and `cli.cmd` from the `_common` directory to automatically gain CLI routing and JSON schema parsing.
3. **Define Schema**: Create `vars.schema.json`. Define your variables, defaults, and descriptions. The framework will automatically generate `--help` documentation and wire these up as environment variables.
   - *Component Dependencies*: To make your app depend on another LibScript tool (e.g., `nodejs` or `postgres`), add `"is_libscript_dependency": true` to the variable property. `cli.sh` and `cli.cmd` will automatically invoke the installation of the specified component, honoring the generated `_STRATEGY` properties, before `setup.sh` begins.
4. **Write `setup.sh`**:
   - Source OS info: `. "$SCRIPT_DIR/../../_common/os_info.sh"`
   - Install OS packages: `depends curl unzip`
   - Download, extract, and configure your tool.
5. **Write Windows Support**: Create `setup_win.ps1` for PowerShell logic.
6. **Write Tests**: Create `test.sh` to compile a Hello World or ping a service.

## Core Best Practices
- **Idempotency**: Your `setup.sh` must be safe to run multiple times. Always check if a config line exists before appending it.
- **Environment Scoping**: Respect the `$PREFIX` variable. Components should be capable of installing globally (e.g., `/usr/local`) or locally (e.g., `./my_env`).
- **Headless Execution**: Never prompt the user for input during `setup.sh`. All inputs must be passed via CLI arguments defined in `vars.schema.json`.

## Features Available to Developers
- `pkg_mgr.sh` for universal dependency installation.
- Built-in daemon registration functions for Systemd, OpenRC, and Windows Services.
- Caching abstraction (downloads automatically hit `LIBSCRIPT_CACHE_DIR`).
