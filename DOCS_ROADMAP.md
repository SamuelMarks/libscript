# Documentation Roadmap

Good documentation is critical for adoption. Here is the plan for expanding the LibScript documentation ecosystem.

## Current State
- Root markdown files (`README.md`, `ARCHITECTURE.md`, `DEVELOPING.md`, `USAGE.md`, `DEPENDENCIES.md`, `TEST.md`, `WINDOWS.md`) provide a comprehensive overview.
- Component-level `README.md` files exist but are sparse.

## Next Steps

1. **Component Documentation Consistency:**
   - Every directory in `_lib/` and `app/` needs a standardized `README.md` explaining what it installs, the configuration options (`vars.schema.json`), and any OS-specific caveats.
   - Script a generator that converts `vars.schema.json` into markdown tables for the component READMEs.

2. **Examples Repository:**
   - Create a `examples/` directory containing complete `install.json` manifests for common setups (e.g., "LEMP stack", "Data Science Workspace", "Rust Web Backend").

3. **Inline Script Documentation:**
   - Add detailed comments to the core functions in `_lib/_common/` (e.g., `pkg_mgr.sh`, `os_info.sh`) explaining the parameters and expected returns.

4. **Static Site:**
   - Compile the markdown files using MkDocs or Docusaurus and host them on GitHub Pages.
