# Documentation Roadmap

## Purpose
Outlines the strategy for evolving LibScript's documentation from repository-level markdown files to a comprehensive, auto-generated static site.

## What Makes This Interesting?
Because every component defines its configuration in `vars.schema.json` and its execution is strictly typed by the CLI router, our documentation can be procedurally generated. We don't just write docs; we compile them directly from the source truth of the components.

## Current State & Next Steps
- [x] Comprehensive root-level Markdown guides covering architecture, usage, and development.
- [x] Standardized `vars.schema.json` format across all components.
- [ ] **Static Site Generation**: Implement a generator (e.g., MkDocs or Docusaurus) that parses `vars.schema.json` files to auto-build feature matrices, configuration tables, and OS compatibility lists for every component.
- [ ] **Examples Repository**: Curate a library of `libscript.json` templates (e.g., LEMP stack, Data Science stack) mapped to interactive tutorials.
- [ ] **Inline Man Pages**: Enhance `libscript.sh --help` to format and paginate output dynamically like standard Unix man pages.
