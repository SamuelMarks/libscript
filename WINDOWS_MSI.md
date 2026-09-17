# WiX Windows Installer (.msi) Architecture & Packaging Guide

This guide documents the Windows Installer (.msi) package generation infrastructure in LibScript,
authored via the WiX (Windows Installer XML) toolset and portable cross-compilers (`wixl`).

## Overview

LibScript generates enterprise-grade `.msi` packages supporting:

- **Hierarchical Feature Selection**: Custom checkboxes for each stack component (MySQL, Redis,
  Waitress, Python, Node.js, Memcached, Meilisearch).
- **Silent & Headless Deployments**: Standard Windows Installer properties allowing full unattended
  enterprise rollout (`msiexec /i ... /qn`).
- **Dynamic Configuration Dialogs**: Automatic dialog generation from `vars.schema.json` component
  variables.
- **Branding and License Agreements**: Integrated RTF/plain-text End User License Agreement (EULA)
  with mandatory acceptance checkboxes, top banner images, side welcome bitmaps, and Add/Remove
  Programs icon association.
- **Sensitive Parameter Masking**: Automatic masking of passwords, keys, and tokens with
  `Password="yes"` in UI controls and registration in `MsiHiddenProperties` to prevent secret
  leakage in verbose installation logs (`msiexec /l*v`).
- **Path and File Browsing**: Native `<Control Type="PathEdit">` and `Browse...` buttons for
  choosing external runtime executables (e.g. host `python3.exe` or `node.exe`).
- **Port Conflict Validation**: VBScript custom actions verifying TCP port availability prior to
  commit.

---

## Command Line Usage

### Interactive Installation

Run the installer with standard Win32 UI:

```cmd
msiexec /i MyStack.msi
```

### Silent Unattended Installation

Install specific components non-interactively with custom port and credential parameters:

```cmd
msiexec /i MyStack.msi /qn /l*v install.log ^
  INSTALL_mysql=1 ^
  PROP_mysql_MYSQL_PORT=3307 ^
  PROP_mysql_MYSQL_ROOT_PASSWORD="SecretPassword123" ^
  INSTALL_python=1 ^
  PROP_python_PYTHON_USE_SYSTEM=1 ^
  PROP_python_PYTHON_CUSTOM_EXECUTABLE_PATH="C:\Python312\python.exe" ^
  INSTALL_memcached=1 ^
  PROP_memcached_MEMCACHED_LISTEN_PORT=11212 ^
  INSTALL_meilisearch=1 ^
  PROP_meilisearch_MEILISEARCH_MASTER_KEY="MasterKey456"
```

### Uninstallation with Data Cleanup

Quietly uninstall all components:

```cmd
msiexec /x MyStack.msi /qn
```

To purge persistent databases and caches during uninstallation:

```cmd
msiexec /x MyStack.msi PURGE_mysql="--purge-data" PURGE_meilisearch="--purge-data" /qn
```

---

## Configuration Variables & Schema

### Common Component Properties

| Component       | Public MSI Property                             | Description                                            | Default |
| :-------------- | :---------------------------------------------- | :----------------------------------------------------- | :------ |
| **MySQL**       | `INSTALL_mysql`                                 | Toggle installation of MySQL component (`1` or `0`)    | `1`     |
|                 | `PROP_mysql_MYSQL_PORT`                         | TCP port for MySQL listener                            | `3306`  |
|                 | `PROP_mysql_MYSQL_REMOTE_URL`                   | Remote connection string (bypasses local installation) | `""`    |
|                 | `PROP_mysql_MYSQL_ROOT_PASSWORD`                | Administrative root password (masked)                  | `""`    |
| **Python**      | `INSTALL_python`                                | Toggle Python runtime installation                     | `1`     |
|                 | `PROP_python_PYTHON_USE_SYSTEM`                 | Use existing host Python rather than bundled runtime   | `0`     |
|                 | `PROP_python_PYTHON_CUSTOM_EXECUTABLE_PATH`     | Path to host `python3.exe`                             | `""`    |
| **Memcached**   | `INSTALL_memcached`                             | Toggle Memcached cache service                         | `1`     |
|                 | `PROP_memcached_MEMCACHED_LISTEN_PORT`          | Custom port to listen on                               | `11211` |
|                 | `PROP_memcached_MEMCACHED_PORT_CONFLICT_POLICY` | Conflict action (`abort`, `auto-increment`, `reuse`)   | `abort` |
| **Meilisearch** | `INSTALL_meilisearch`                           | Toggle Meilisearch engine                              | `1`     |
|                 | `PROP_meilisearch_MEILISEARCH_PORT`             | HTTP port                                              | `7700`  |
|                 | `PROP_meilisearch_MEILISEARCH_MASTER_KEY`       | Master authentication key (masked)                     | `""`    |
|                 | `PROP_meilisearch_MEILISEARCH_CUSTOM_URL`       | Remote cluster URL alternative                         | `""`    |

---

## Branding & Visual Asset Requirements

To configure custom branding in `packaging/template_msi.*` or via `libscript.sh package-as msi`:

- **License Agreement**: `--license <path>` (Plain text or `.rtf`). Automatically formatted into a
  scrollable EULA dialog with acceptance checkbox.
- **Application Icon**: `--icon <path.ico>`. Embedded into binary and registered in
  `ARPPRODUCTICON`.
- **Top Banner**: `--banner-top <path.bmp>`. Bitmap displayed on top header (Recommended size:
  493x58 pixels).
- **Side Splash Banner**: `--banner-side <path.bmp>`. Bitmap displayed on left pane of Welcome and
  Completion dialogs (Recommended size: 493x312 pixels).
