# msi-rs Preloader & Asset Catalog

## Purpose & Overview

Manages offline asset preloading, download verification, checksum generation, and manifest synthesis
for `msi-rs` offline media and airgap bundles.

## Usage

```sh
# Preload all required installation assets for target plan
./preload_assets.sh --plan <execution_plan.json> --dest <target_dir>

# Generate asset catalog and checksum verification database
./catalog.sh --source <staged_assets_dir> --output <catalog.json>
```

## Available Scripts

- `preload_assets.sh` / `.cmd`: Hydrates offline asset caches from verified upstream mirrors.
- `catalog.sh` / `.cmd`: Verifies cryptographic hashes and indexes payload components into catalog
  metadata.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
