# Documentation Roadmap

This document outlines the planned improvements and ongoing initiatives for LibScript's documentation. The goal is to provide clear, technically accurate guides for utilizing the framework's native execution and generation capabilities.

## Current Objectives

- **Generator Documentation:** Provide detailed examples of utilizing the `package_as` command to generate Dockerfiles, Docker Compose setups, and native OS installers (Windows, Linux, FreeBSD, macOS).
- **Configuration Management Integration:** Detail how LibScript can be called from existing tools (like Chef, Ansible, and Puppet) to simplify playbook complexity.
- **Stack Templates:** Document common stack definitions (e.g., LAMP, MEAN) using the `libscript.json` format.

## Future Enhancements

1. **Procedural Generation:** Develop tools (like `generate_html_docs.sh`) to automatically generate reference documentation from the `vars.schema.json` files of each component.
2. **Interactive Examples:** Provide interactive CLI or TUI examples within the documentation to demonstrate stack building.
3. **Compatibility Matrices:** Automatically maintain tables indicating which components are supported on which operating systems.
