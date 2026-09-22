# Packaging Infrastructure

This directory contains schemas, templates, and utilities for compiling and synthesizing native OS
installers and distribution packages from LibScript stack manifests.

## Supported Installer Formats

- **NSIS (`template_nsis.*`)**: Nullsoft Scriptable Install System script templates for building
  lightweight Windows executable installers (`.exe`).
- **Inno Setup (`template_inno.*`)**: Inno Setup script templates for creating customized Windows
  installers (`.exe`).
- **MSI (`template_msi.*` / `build_msi.*`)**: WiX-based Windows Installer package definitions
  (`.msi`).
- **Open edX Stack MSI (`build_openedx_msi.*`)**: Production-grade Windows installer supporting dual
  distribution: lightweight online (~4 MB) and completely self-contained air-gapped offline (~1 GB).
- **Offline Cache Hydration (`hydrate_offline_cache.*`)**: Downloads, validates SHA-256 integrity,
  and stages runtime archives, datastores, pip wheels, and codebase packages.
- **Payload Harvester (`harvest_payload.*`)**: Gathers and filters the LibScript repository honoring
  `.gitignore` rules and generates modular WiX XML fragments with optional offline cache embedding.
- **Resilient Browser Launcher (`launch_browser.*`)**: Post-installation browser trigger with
  automatic detection and graceful desktop `.url` shortcut fallback.
- **Schemas**:
  - `installer.schema.json`: Formal JSON schema specifying options, metadata, shortcuts, and scope.
  - `packaging.schema.json`: Unified packaging specification and multi-format target rules.
  - `offline.schema.json`: Specification schema for air-gapped dependency manifests and SHA-256
    checksums.

## Air-Gapped Cache Structure (`[INSTALLFOLDER]\libscript\cache`)

When building offline packages, artifacts are harvested into a standardized cache layout:

```
[INSTALLFOLDER]\libscript\cache
├── manifest.json                # Copy of offline_bundle.json
├── checksums.sha256             # Verification hash manifest
├── runtimes
│   ├── python-3.11.9-amd64.zip
│   └── node-v20.17.0-win-x64.zip
├── databases
│   ├── mysql-8.0.39-winx64.zip
│   ├── redis-7.0.zip
│   ├── mongodb-windows-7.0.zip
│   └── meilisearch-windows-amd64.exe
├── wheels\                      # Pre-downloaded pip wheels
│   ├── waitress-3.0.0-py3-none-any.whl
│   └── *.whl
├── npm\                         # Pre-cached frontend tarballs
└── codebase
    ├── edx-platform.zip
    └── demo-course.tar.gz
```

## WiX Multi-Cabinet Partitioning Strategy

Offline MSI packages exceeding 500 MB partition payloads across dedicated Media cabinets to avoid
Windows Installer 2 GB single-cabinet limits:

```xml
<!-- Offline Variant (Multi-cab partition) -->
<Media Id="1" Cabinet="engine.cab" EmbedCab="yes" CompressionLevel="high" />
<Media Id="2" Cabinet="runtimes.cab" EmbedCab="yes" CompressionLevel="medium" />
<Media Id="3" Cabinet="databases.cab" EmbedCab="yes" CompressionLevel="medium" />
<Media Id="4" Cabinet="codebase.cab" EmbedCab="yes" CompressionLevel="medium" />
```

Harvested files are routed to specific cabinets using `DiskId="X"` based on file classification:

- Core engine, CLI, scripts -> `engine.cab` (DiskId 1)
- Python & Node.js runtimes -> `runtimes.cab` (DiskId 2)
- MySQL, Redis, MongoDB, Meilisearch -> `databases.cab` (DiskId 3)
- Application codebase & courseware -> `codebase.cab` (DiskId 4)

## Containerization & Export Architecture

### Dockerfile Online Layer Caching with `ADD`

In online mode, `package-as docker --online` leverages Docker layer caching:

```dockerfile
ENV LIBSCRIPT_CACHE_DIR="/opt/libscript_cache"
ADD https://.../python-3.11.9.tar.gz /opt/libscript_cache/python/python-3.11.9.tar.gz
COPY . /opt/libscript
RUN ./libscript.sh install python 3.11
```

Docker re-downloads the remote layer only when HTTP headers (`ETag`, `Last-Modified`) change.

### Dockerfile Air-Gapped Offline Mode

In offline mode, `package-as docker --offline` generates an isolated Dockerfile without remote
fetch:

```dockerfile
ENV LIBSCRIPT_OFFLINE="1"
ENV PIP_NO_INDEX="1"
ENV PIP_FIND_LINKS="/opt/libscript_cache/wheels"
ENV npm_config_offline="true"
COPY cache/ /opt/libscript_cache/
COPY . /opt/libscript
RUN ./libscript.sh install python 3.11 --offline
```

Builds successfully without network access via `docker build --network none .`.

### Docker Compose Air-Gapped Multi-Service Export

`package-as docker-compose --offline` generates an isolated multi-service topology:

- Mounts shared read-only cache: `libscript_offline_cache:/opt/libscript_cache:ro`
- Internal isolated network: `networks: internal_network: internal: true`
- Environment variables: `LIBSCRIPT_OFFLINE=1`, `MYSQL_HOST=mysql`, `REDIS_HOST=redis`, etc.
- Healthchecks use local utilities (e.g. `nc -z 127.0.0.1 <port>`) without external `curl`.

## Usage

```sh
# Online and Offline MSI builds
./packaging/build_openedx_msi.sh --online
./packaging/build_openedx_msi.sh --offline --hydrate-cache

# Docker and Compose exports
./libscript.sh package-as docker stacks/cms/openedx --online
./libscript.sh package-as docker stacks/cms/openedx --offline
./libscript.sh package-as docker-compose stacks/cms/openedx --offline
```
