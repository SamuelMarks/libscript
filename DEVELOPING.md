# Developing LibScript

LibScript is an open-source framework, and community contributions to expand its component library are welcome. Developing a new component leverages the existing cross-platform execution and generation architecture.

## How to Scaffold a Component

Components are located within the `_lib` directory under relevant categories (e.g., `_lib/_toolchain/my_tool`).

To create a new component:
1. **Create the Component Directory**: Place it in the appropriate `_lib` subfolder.
2. **Define `vars.schema.json`**: Outline the tool's dependencies, required environment variables, and exposed ports.
3. **Write `setup.sh`**: Implement the POSIX shell script to download, extract, and configure the tool.
4. **Write `setup_win.ps1` or `setup_win.cmd`**: Provide the Windows implementation for the tool's setup.

## Contribution Benefits

By defining a component with a `vars.schema.json` and basic setup scripts, it automatically inherits support for the `package_as` generators. The new component can immediately be compiled into a Dockerfile, an MSI installer, or integrated into a generated `docker-compose.yml` stack.
