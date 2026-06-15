# Documentation Roadmap

This document outlines the planned improvements and ongoing initiatives for LibScript's documentation. The goal is to provide clear, technically accurate guides for utilizing the framework's native execution and generation capabilities.

## Current Objectives

- **Automated Schema Synchronization:** Ensure all `README.md` files dynamically inherit and display accurate variable tables from `vars.schema.json` and `base_vars.schema.json`. *(Implemented via `devtools/docs-gen`)*
- **Dynamic Compatibility Matrices:** Automatically detect and maintain "Platform Support" tables in component READMEs by inspecting execution scripts. *(Implemented via `devtools/docs-gen`)*
- **Generator Documentation:** Provide detailed examples of utilizing the `package_as` command to generate Dockerfiles, Docker Compose setups, and native OS installers (Windows, Linux, FreeBSD, macOS).

## Future Enhancements

1. **Procedural Web Docs Generation:** Expand the `generate_html_docs.sh` toolchain to synthesize an entire static documentation website utilizing the auto-generated markdown tables.
2. **Interactive Examples:** Provide interactive CLI or TUI examples within the documentation to demonstrate stack building.
3. **Configuration Management Integration:** Detail how LibScript can be called from existing tools (like Chef, Ansible, and Puppet) to simplify playbook complexity.
4. **Stack Templates:** Document common stack definitions (e.g., LAMP, MEAN) using the `libscript.json` format.