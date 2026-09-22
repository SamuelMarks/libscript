# Cross-Platform Packaging & Branding Customization Guide

LibScript provides a unified packaging architecture to synthesize native, production-grade
installation artifacts for Windows, macOS, Linux, and Cloud/PaaS targets.

## Supported Packaging Targets & Visual Branding Features

| Target Format                    | Generator Script                           | Custom License / EULA              | Custom Logo / Icon                | Top Banner                     | Left/Side Splash Banner        | Non-Interactive Silent Flag         |
| :------------------------------- | :----------------------------------------- | :--------------------------------- | :-------------------------------- | :----------------------------- | :----------------------------- | :---------------------------------- |
| **WiX Windows Installer (.msi)** | `packaging/template_msi.*`                 | Scrollable RTF EULA with checkbox  | `.ico` (embedded & ARP icon)      | `WixUIBannerBmp` (493x58)      | `WixUIDialogBmp` (493x312)     | `/qn`                               |
| **Inno Setup (.exe)**            | `packaging/template_inno.*`                | `LicenseFile=` directive           | `SetupIconFile=` (`.ico`)         | `WizardSmallImageFile` (55x58) | `WizardImageFile` (164x314)    | `/VERYSILENT /SUPPRESSMSGBOXES`     |
| **NSIS (.exe)**                  | `packaging/template_nsis.*`                | Modern UI `Page license`           | `MUI_ICON` (`.ico`)               | `MUI_HEADERIMAGE_BITMAP`       | `MUI_WELCOMEFINISHPAGE_BITMAP` | `/S`                                |
| **macOS Disk Image (.dmg)**      | `cli/commands/packaging/formats/pkg_dmg.*` | Embedded SLA agreement via UDIF    | Custom Volume `.icns`             | N/A                            | Finder background (600x400)    | Headless mount via `hdiutil attach` |
| **Debian (.deb)**                | `cli/commands/packaging/formats/pkg_deb.*` | `/usr/share/doc/.../copyright`     | Desktop icon `/usr/share/pixmaps` | N/A                            | N/A                            | `DEBIAN_FRONTEND=noninteractive`    |
| **Red Hat (.rpm)**               | `cli/commands/packaging/formats/pkg_rpm.*` | `/usr/share/licenses/.../LICENSE`  | Desktop icon `/usr/share/pixmaps` | N/A                            | N/A                            | `-y` / `--nogpgcheck`               |
| **Terminal UI (TUI)**            | `cli/commands/packaging/formats/pkg_tui.*` | Terminal pager with `[Y/n]` prompt | ASCII / Sixel logo display        | Header bar                     | N/A                            | `--accept-license --yes`            |

---

## Centralized Configuration (`libscript.json`)

To configure visual assets and custom agreements in your stack manifest:

```json
{
  "name": "MyEnterpriseApp",
  "version": "2.4.0",
  "branding": {
    "license": {
      "file": "legal/LICENSE.txt",
      "type": "text",
      "require_agreement": true,
      "agreement_checkbox_text": "I accept the software license terms"
    },
    "images": {
      "icon": "assets/app.ico",
      "logo": "assets/logo.png",
      "banner_top": "assets/installer_header.bmp",
      "banner_side": "assets/installer_sidebar.bmp",
      "dmg_background": "assets/dmg_bg.png"
    },
    "text": {
      "welcome_title": "Welcome to MyEnterpriseApp Setup",
      "welcome_body": "This wizard installs MyEnterpriseApp and configured datastores on your machine.",
      "finish_title": "Installation Complete",
      "finish_body": "MyEnterpriseApp is now running as a service. Navigate to http://localhost:8000"
    }
  }
}
```

---

## Unified Command Line Arguments

All packaging generators accept normalized command-line flags across POSIX `/bin/sh`, Windows batch
(`.cmd`), and PowerShell (`.ps1`):

```sh
# Generate WiX MSI package
./libscript.sh package-as msi
  --app-name "MyEnterpriseApp"
  --license-file "legal/LICENSE.txt"
  --icon "assets/app.ico"
  --banner-top "assets/header.bmp"
  --banner-side "assets/sidebar.bmp"

# Generate Inno Setup package
./libscript.sh package-as inno
  --app-name "MyEnterpriseApp"
  --license-file "legal/LICENSE.txt"
  --banner-side "assets/sidebar.bmp"

# Generate NSIS package
./libscript.sh package-as nsis
  --app-name "MyEnterpriseApp"
  --license-file "legal/LICENSE.txt"
  --icon "assets/app.ico"
```

---

## Dual Distribution Variants (Online & Air-Gapped Offline)

LibScript supports building two distinct deployment variants from the same stack recipes:

1. **Online Variant (`--online`)**:
   - Lightweight installer (~4 MB).
   - Dynamically resolves runtimes and datastores from official network mirrors during installation.
   - Recommended for developer environments and dynamic cloud VMs.

2. **Air-Gapped Offline Variant (`--offline`)**:
   - Self-contained archive/MSI (~800 MB - 1.5 GB).
   - Pre-bundles runtimes, datastore binaries, pip wheels, and codebase archives.
   - Strictly prohibits network access during installation.
   - Utilizes multi-cabinet partitioning in WiX (`engine.cab`, `runtimes.cab`, `databases.cab`,
     `codebase.cab`) to avoid 2 GB MSI cabinet limits.
   - Recommended for secure intranets, defense, banking, and air-gapped server environments.

---

## Container Export Branding & Caching Architecture

When exporting to containerized targets (`package-as docker` and `package-as docker-compose`):

- **Online Dockerfile Export**: Synthesizes `ADD <url> /opt/libscript_cache/<pkg>/<filename>`
  directives to utilize Docker's native layer caching. Remote artifacts are downloaded only once
  unless remote HTTP ETag or Last-Modified headers change.
- **Air-Gapped Offline Dockerfile Export**: Uses `COPY cache/ /opt/libscript_cache/` in the
  Dockerfile header, sets `ENV LIBSCRIPT_OFFLINE=1`, and prohibits all `curl`/`wget`/`git` commands,
  allowing hermetic builds via `docker build --network none .`.
- **Multi-Service Docker Compose Export**: Produces an isolated multi-service topology mounting a
  shared read-only cache volume (`libscript_offline_cache:/opt/libscript_cache:ro`), an internal
  isolated network (`internal: true`), and local socket healthcheck probes.
