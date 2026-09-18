# Packaging Assets

Branding and graphic assets utilized during Windows Installer (`.msi`) generation and setup wizard
synthesis.

## Assets Directory Structure

- `openedx.ico`: Multi-resolution Windows icon (16x16, 32x32, 48x48, 256x256) used for setup
  binaries, Add/Remove Programs registry entries, and desktop shortcuts.
- `openedx_banner_top.bmp`: 493x58 24-bit bitmap banner displayed across the top header of standard
  WiX dialog windows.
- `openedx_banner_side.bmp`: 164x312 24-bit bitmap splash graphic displayed on the left pane of
  welcome, maintenance, and completion dialogs.
- `openedx_eula.rtf`: End User License Agreement formatted in Rich Text Format (RTF) required by the
  WiX `WixUI_InstallDir` and customized UI dialog sets.

## Generation & Usage

Binary media and icon assets (`.ico`, `.bmp`, `.png`) are intentionally omitted from git tracking in
this repository.

They are:

1. Sourced from the companion CC0 assets repository (`../cc0-assets/libscript/openedx/assets/`) if
   present.
2. Generated dynamically on the fly during packaging builds via
   `packaging/generate_openedx_branding.sh` / `generate_openedx_branding.cmd`.
