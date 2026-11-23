# Tier 4 (`T4`) Multicloud Marketplace Publishing (`infrastructure/marketplace/`)

## Overview

`infrastructure/marketplace/` validates and publishes multi-appliance cloud Marketplace offers
governed by `marketplace-offer.schema.json` across **AWS Marketplace**, **Microsoft Azure
Marketplace**, and **Google Cloud Marketplace** via `./libscript.sh publish-marketplace`.

## Scripts & Schema

- **`marketplace-offer.schema.json`**: Declarative offer metadata, SKU pricing, EULA, appliance
  image references, network policy, and SBOM contract.
- **`verify_compliance.{sh,cmd}`**: Pre-publish security and compliance gate verifying EULA
  presence, SPDX 2.3 SBOM completeness, zero hardcoded secrets, and zero exposed public
  admin/database ports.
- **`publish.{sh,cmd}`**: Orchestrates compliance verification, image import (`import-image`), and
  per-cloud artifact emission (`--stage-only` or live submission).
- **`aws.{sh,cmd}`**: Emits AWS Marketplace Catalog API `StartChangeSet` JSON payloads and
  CloudFormation templates.
- **`azure.{sh,cmd}`**: Emits Azure Managed Application `.zip` bundles (`mainTemplate.json` +
  `createUiDefinition.json`).
- **`gcp.{sh,cmd}`**: Emits Google Cloud Producer Portal Terraform Blueprints and deployment
  metadata.

## Usage

```sh
./libscript.sh publish-marketplace workloads/constellations/openedx-unikernel-pod/marketplace/offer.json --clouds=aws,azure,gcp --stage-only
```

```cmd
.\libscript.cmd publish-marketplace workloads\constellations\openedx-unikernel-pod\marketplace\offer.json --clouds=aws,azure,gcp --stage-only
```
