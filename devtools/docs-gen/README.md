# Automated Markdown Documentation Generator (`devtools/docs-gen/`)

## Overview

`devtools/docs-gen/` synchronizes component and subsystem `README.md` tables with their declarative
JSON Schema contracts (`vars.schema.json`, `schemas/vars/*.schema.json`, and
`engine/schemas/base_vars.schema.json`).

## Scripts

- **`generate_markdown_docs.sh`**: Merges each module's `vars.schema.json` and declared
  `"x-libscript-var-packs"` into Markdown tables injected between `<!-- BEGIN_VARS -->` and
  `<!-- END_VARS -->`, synchronizes `<!-- BEGIN_PLATFORMS -->` markers, updates
  `engine/common/README.md` from `engine/schemas/base_vars.schema.json`, and formats modified
  Markdown files with `prettier`.
- **`inject_markers.sh` & `inject.awk`**: Ensures `<!-- BEGIN_VARS -->` and
  `<!-- BEGIN_PLATFORMS -->` structural markers exist in component `README.md` files.

## Usage

```sh
./devtools/docs-gen/generate_markdown_docs.sh
```
