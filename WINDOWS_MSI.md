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
  AGREE_ALL_LICENSES=1 ^
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

> **Mandatory Multi-License Agreement in Unattended Mode:** When an installer bundles third-party
> software components (such as MySQL, Redis, MongoDB, Python, Node.js, Meilisearch), non-interactive
> installations (`/qn` or `/qb`) strictly require explicit license acceptance. Pass
> `AGREE_ALL_LICENSES=1` to acknowledge and accept all bundled software licenses, or specify
> individual acceptance flags (e.g. `LICENSE_ACCEPTED_mysql=1 LICENSE_ACCEPTED_redis=1 ...`). If
> omitted, installation terminates immediately prior to file extraction with MSI exit code `1603`
> (`ERROR_INSTALL_FAILURE`).

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

---

## Embedded LibScript Engine & Self-Contained Deployment

Every LibScript MSI installer embeds the complete execution engine, recipe modules, and stack
orchestration scripts into a dedicated subfolder (`[INSTALLFOLDER]\libscript`), ensuring complete
standalone autonomy without requiring pre-installed host packages or external tools:

```
C:\Program Files (x86)\OpenEdX\
├── cli.cmd                      # Management console dispatcher
├── healthcheck.cmd              # Full-stack diagnostic probe
├── ...                          # Stack helper and control scripts
└── libscript\                   # Full embedded LibScript engine
    ├── libscript.cmd            # Root Windows batch engine
    ├── libscript.sh             # Root POSIX /bin/sh engine
    ├── _lib\                    # Core runtime, database, and cache recipes
    ├── cli\                     # CLI dispatchers
    ├── netctl\                  # Networking managers
    ├── packaging\               # WiX generators, branding tools, and browser launcher
    └── stacks\                  # Platform and stack configurations
```

### WiX Multi-Fragment Synthesis

The installer utilizes a modular multi-fragment architecture compiled via `candle.exe`/`light.exe`
or `wixl`:

1. **`Product.wxs`**: Defines Product properties, UI dialog flows (Simple and Advanced modes), and
   deferred elevated CustomActions.
2. **`Product_payload.wxs`**: Generated dynamically by `packaging/harvest_payload.sh` or
   `packaging/harvest_payload.cmd`, harvesting all repository files while filtering out `.git`,
   `tests_tmp/`, build artifacts, and ignored patterns.

### Custom Action Execution Pipeline

Deferred elevated custom actions invoke the embedded engine directly from
`[INSTALLFOLDER]libscript`:

```xml
<CustomAction Id="InstallOpenEdXService"
              Directory="INSTALLFOLDER"
              ExeCommand="cmd.exe /c &quot;[INSTALLFOLDER]libscript\libscript.cmd&quot; install stacks/cms/openedx ..."
              Execute="deferred"
              Return="check"
              Impersonate="no" />
```

### Resilient Browser Launch & Fallback

The post-install browser trigger invokes `packaging/launch_browser.cmd`. If no web browser is
registered on the host system, it creates desktop `.url` Internet Shortcuts pointing to the LMS and
CMS endpoints, avoiding blocking Windows modal error popups.

---

## Online vs Offline Air-Gapped Deployments

LibScript provides dual-distribution packaging architecture for Windows environments:

| Feature / Dimension           | Online Variant (`OpenEdX-Online-Setup.msi`) | Offline Variant (`OpenEdX-Offline-Setup.msi`)                           |
| :---------------------------- | :------------------------------------------ | :---------------------------------------------------------------------- |
| **Package Size**              | ~4 MB                                       | ~800 MB - 1.5 GB                                                        |
| **Network Access**            | Required during installation                | Zero (100% Air-Gapped Network Isolation)                                |
| **Target Audience**           | Developer workstations, dynamic cloud VMs   | Defense, banking, secure intranets, air-gaps                            |
| **Embedded Payload**          | LibScript engine and stack recipes          | LibScript engine + pre-downloaded cache                                 |
| **WiX Cabinet Architecture**  | Single `engine.cab` (high compression)      | Multi-cabinet partition (`engine`, `runtimes`, `databases`, `codebase`) |
| **Runtimes (Python, Node)**   | Downloaded at installation time             | Pre-extracted from `cache\runtimes`                                     |
| **Datastores (MySQL, Redis)** | Fetched from official mirrors               | Pre-extracted from `cache\databases`                                    |
| **Python Packages**           | Resolved dynamically via PyPI               | `pip install --no-index --find-links` from wheels                       |
| **Codebase Delivery**         | Remote `git clone`                          | Pre-bundled `edx-platform.zip` extraction                               |
| **Installation Duration**     | 10 - 30 minutes (dependent on bandwidth)    | 2 - 5 minutes (local I/O extraction)                                    |

### Build Commands

#### 1. Online Lightweight Variant (~4 MB)

```sh
# POSIX / macOS / Linux build host
./packaging/build_openedx_msi.sh --online --out OpenEdX-Online-Setup

# Windows build host
call packaging\build_openedx_msi.cmd --online --out OpenEdX-Online-Setup
```

#### 2. Hydrating the Offline Artifact Cache

Before compiling the offline installer, download and verify the offline dependencies using the
bundle manifest:

```sh
# POSIX build host
./packaging/hydrate_offline_cache.sh \
  --manifest stacks/cms/openedx/offline_bundle.json \
  --cache-dir cache/ \
  --wheels \
  --codebase

# Windows build host
call packaging\hydrate_offline_cache.cmd ^
  --manifest stacks\cms\openedx\offline_bundle.json ^
  --cache-dir cache\ ^
  --wheels ^
  --codebase
```

#### 3. Offline Air-Gapped Variant (~1 GB)

```sh
# POSIX build host (compiles with multi-cabinet partitioning)
./packaging/build_openedx_msi.sh --offline --cache-dir cache/ --out OpenEdX-Offline-Setup

# Windows build host
call packaging\build_openedx_msi.cmd --offline --cache-dir cache\ --out OpenEdX-Offline-Setup
```

Alternatively, use the unified CLI dispatcher:

```sh
./libscript.sh package-as msi stacks/cms/openedx --online
./libscript.sh package-as msi stacks/cms/openedx --offline
```

### Multi-Cabinet Partitioning Architecture

To support offline payloads exceeding 500 MB without encountering the Windows Installer 2 GB
single-cabinet ceiling or memory exhaustion during compression, the WiX manifest partitions files
across dedicated media cabinets:

```xml
<!-- Offline Variant (Multi-cab partition) -->
<Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="high" />
<Media Id="2" Cabinet="runtimes.cab" EmbedCab="yes" CompressionLevel="medium" />
<Media Id="3" Cabinet="databases.cab" EmbedCab="yes" CompressionLevel="medium" />
<Media Id="4" Cabinet="codebase.cab" EmbedCab="yes" CompressionLevel="medium" />
```

Harvested files are routed to specific `DiskId` attributes based on subfolder classification:

- `cache/runtimes/*` -> DiskId 2
- `cache/databases/*` -> DiskId 3
- `cache/codebase/*` -> DiskId 4
- LibScript engine, CLI, and stack scripts -> DiskId 1

### Network Connectivity Detection Custom Action

The installer incorporates custom action `CA_CheckNetworkConnection`:

- **In Online Mode**: Tests outbound TCP connectivity to PyPI and GitHub. If disconnected, displays
  an advisory warning dialog guiding the user to connect to the Internet or deploy the Offline
  Air-Gapped MSI.
- **In Offline Mode**: Skips connectivity probing entirely, suppresses external mirror resolution,
  and proceeds straight to local air-gapped extraction.

### Air-Gapped Enterprise Deployment Checklist

Before rolling out `OpenEdX-Offline-Setup.msi` into production air-gapped zones:

- [ ] **Cache Hydration & Integrity**: Run `hydrate_offline_cache.* --verify-only` to ensure all
      SHA-256 integrity hashes match `offline_bundle.json`.
- [ ] **Zero Network Dependency**: Verify that all `git clone`, `curl`, `wget`, and PyPI queries are
      inhibited by checking `PROP_OPENEDX_OFFLINE=1`.
- [ ] **Silent Installation**: Test unattended installation with log output:
      `cmd     msiexec /i OpenEdX-Offline-Setup.msi /qn /l*v C:\libscript\offline_install.log     `
- [ ] **Port Availability**: Verify default ports (8000, 8001, 3306, 6379, 27017, 7700) are not
      occupied by existing services.
- [ ] **Clean Removal**: Test silent uninstallation (`msiexec /x OpenEdX-Offline-Setup.msi /qn`) to
      confirm clean teardown of files and Windows services.

### Troubleshooting Offline Deployments

1. **Missing Artifact in Cache**:
   - Diagnostic: MSI log indicates `[WARN] Offline mode requested but no cache directory found`.
   - Resolution: Ensure the hydrated `cache/` folder is passed with `--include-cache <dir>` during
     payload harvesting or set `LIBSCRIPT_CACHE_DIR`.
2. **Pip Index Connection Attempt**:
   - Diagnostic: Pip attempts network connection to PyPI and times out.
   - Resolution: Ensure `PIP_NO_INDEX=1` and
     `PIP_FIND_LINKS="[INSTALLFOLDER]\libscript\cache\wheels"` are defined in the subshell
     environment.
3. **Database Socket Timeout**:
   - Diagnostic: Port check fails for MySQL or MongoDB.
   - Resolution: Review `%OPENEDX_INSTALL_DIR%\logs` to verify local service initialization and
     check that antivirus/EDR software is not blocking loopback TCP bindings.

---

## Modular Zero-.EXE MSI Architecture & Side-by-Side Component Reuse

LibScript supports decomposing monolithic stack installers into **modular standalone component
MSIs** chained via Windows Installer 4.5+ native multi-package transactions (`MsiEmbeddedChainer`)
with **ZERO `.exe` bootstrappers**.

### Standalone Component MSIs

Every core dependency is compiled into a self-contained, reference-counted `.msi`:

- `libscript-mysql-${VERSION}.msi` (`LibScript_MySQL` service on port 3306)
- `libscript-redis-${VERSION}.msi` (`LibScript_Redis` service on port 6379)
- `libscript-mongodb-${VERSION}.msi` (`LibScript_MongoDB` service on port 27017)
- `libscript-python-${VERSION}.msi` (Shared runtime at `[ProgramFiles64Folder]LibScript\Python311`)
- `libscript-nodejs-${VERSION}.msi` (Shared runtime at `[ProgramFiles64Folder]LibScript\Node20`)
- `libscript-meilisearch-${VERSION}.msi` (`LibScript_Meilisearch` service on port 7700)
- `openedx-core-${VERSION}.msi` (LMS/CMS application files, virtualenv wheels, CLI scripts)

### Deterministic GUID Identity (`packaging/guid_registry.json`)

All components adhere to fixed `UpgradeCode` lineages and shared `ComponentId` GUIDs registered in
`packaging/guid_registry.json`:

- **MySQL Service Component GUID**: `{5B2783B0-9A1F-4348-9F93-87CE43C21001}`
- **MySQL UpgradeCode**: `{E0F45901-83B4-4B21-9B5A-01D38FE81001}`

### Side-by-Side Application Reuse (e.g. Open edX and WordPress)

Multiple applications can safely share a single MySQL service on Windows without interference:

1. **Shared Engine, Isolated Schemas**:
   - Single running MySQL instance on `127.0.0.1:3306`.
   - Open edX provisions database `openedx` and user `openedx`@`localhost`.
   - WordPress provisions database `wordpress` and user `wordpress`@`localhost`.
2. **Windows Installer Reference Counting**:
   - Both installers reference identical Component GUID `{5B2783B0-9A1F-4348-9F93-87CE43C21001}`
     with `SharedDllRefCount="yes"`.
   - Uninstalling Open edX drops only its `openedx` schema and decrements the component reference
     count from 2 to 1.
   - The MySQL Windows service and WordPress database remain running and intact.
   - The MySQL Windows service is only removed when the last consuming application is uninstalled
     (ref count reaches 0).
