# Component-Package-Manager Scaffolder (`cli/commands/scaffold`)

## Overview

The `scaffold` (alias `new-component`) command automates the creation of new Tier 1 LibScript
component-package-managers under `_lib/<category>/<component>/`. It supports both:

1. **Interactive Prompter Mode** (`--interactive` / default): Guides a human maintainer through
   selecting the component name, category, description, installation method, upstream version
   discovery scheme, download URL templates, archive formats, OS/architecture support, and
   background service/hook options, optionally exporting the answers to a reusable JSON
   specification file.
2. **Non-Interactive JSON Mode** (`--from-json=<file>`): Deterministically and idempotently
   generates all required POSIX `/bin/sh` (`.sh`), Windows Batch (`.cmd`), JSON schema
   (`vars.schema.json`), manifest (`manifest.json`), and documentation (`README.md`) files from a
   JSON file conforming to `component-scaffold.schema.json`.

## Usage

### Interactive Prompter

```sh
./libscript.sh scaffold
# or on Windows:
.\libscript.cmd scaffold
```

To save the interactive responses to a JSON file for reproducible replay:

```sh
./libscript.sh scaffold --interactive --export-json=my-component.scaffold.json
```

### Non-Interactive JSON Generation

```sh
./libscript.sh scaffold --from-json=my-component.scaffold.json
# or on Windows:
.\libscript.cmd scaffold --from-json=my-component.scaffold.json
```

### CLI Flag Overrides

```sh
./libscript.sh scaffold
  --non-interactive
  --name=zoxide
  --category=utilities
  --description="A smarter cd command inspired by z and autojump."
  --github-repo=ajeetdsouza/zoxide
  --version-scheme=github-release
  --os=all
```
