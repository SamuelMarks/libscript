# LibScript Packaging Formats

## Overview

Implements export engines for various software packaging ecosystems:

- `docker` / `docker_compose`: Generates OCI container images and Compose manifests.
- `deb`, `rpm`, `apk`, `pkg`, `txz`: Native Linux and BSD package archives.
- `nsis`, `msi`, `inno`: Windows native installers.
- `dmg`: macOS disk image bundles.
- `tui`: Terminal user interface installation packages.
