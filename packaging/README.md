# Packaging Infrastructure

This directory contains schemas, templates, and utilities for compiling and synthesizing native OS
installers and distribution packages from LibScript stack manifests.

## Supported Installer Formats

- **NSIS (`template_nsis.*`)**: Nullsoft Scriptable Install System script templates for building
  lightweight Windows executable installers (`.exe`).
- **Inno Setup (`template_inno.*`)**: Inno Setup script templates for creating customized Windows
  installers (`.exe`).
- **MSI (`template_msi.*`)**: WiX-based Windows Installer package definitions (`.msi`).
- **Schema (`installer.schema.json`)**: Formal JSON schema specifying options, metadata, shortcuts,
  registry keys, and installation scope for installer generation.

## Usage

Packaging commands are accessible via the main LibScript CLI:

```sh
./libscript.sh package-as nsis
./libscript.sh package-as inno
./libscript.sh package-as msi
```
