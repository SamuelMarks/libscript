# Tier 4 (`T4`) Infrastructure Resource: Cloud CDN & Distribution (`infrastructure/resources/cdn/`)

## Overview

Multicloud interface for managing content delivery networks and edge caching. Adapter-only component
without binary installer lifecycle.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure cdn`
(`infrastructure/resources/cdn/cli.{sh,cmd}`).

## Scripts

- `api.{sh,cmd}`
- `cli.{sh,cmd}`
- `env.{sh,cmd}`
- `logs.{sh,cmd}`
- `setup.{sh,cmd}`
- `setup_generic.{sh,cmd}`
- `status.{sh,cmd}`
- `test.{sh,cmd}`
- `uninstall.{sh,cmd}`

## Usage

```sh
./libscript.sh infrastructure cdn --help
```

```cmd
.\libscript.cmd infrastructure cdn --help
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default |
| :------------------------------------- | :---------------------------------------------------------------------------------------------------------- | :------ |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `-`     |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `-`     |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `-`     |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `-`     |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `-`     |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `-`     |
| `LIBSCRIPT_CLOUD`                      | Cloud provider (aws, gcp, azure).                                                                           | `-`     |
| `LIBSCRIPT_BUCKET`                     | The name of the object storage bucket acting as origin.                                                     | `-`     |
| `LIBSCRIPT_DOMAIN`                     | Custom domain for the CDN.                                                                                  | `-`     |
| `LIBSCRIPT_CERT_ID`                    | SSL certificate identifier for custom domains.                                                              | `-`     |
| `LIBSCRIPT_DIST_ID`                    | CDN distribution ID (e.g. for delete or invalidate).                                                        | `-`     |
| `LIBSCRIPT_PATHS`                      | Paths to invalidate on the CDN.                                                                             | `-`     |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
