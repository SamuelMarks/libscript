# Tier 4 (`T4`) Infrastructure Resource: Cloud SSL Certificates (`infrastructure/resources/cert/`)

## Overview

Multicloud interface for managing managed SSL certificates. Adapter-only component without binary
installer lifecycle.

This `T4` resource module provides uniform cross-cloud operations across AWS, Azure, and GCP,
dispatched through `./libscript.sh infrastructure cert`
(`infrastructure/resources/cert/cli.{sh,cmd}`).

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
./libscript.sh infrastructure cert --help
```

```cmd
.\libscript.cmd infrastructure cert --help
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default           |
| :------------------------------------- | :---------------------------------------------------------------------------------------------------------- | :---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `-`               |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `-`               |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `-`               |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `-`               |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `-`               |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `-`               |
| `LIBSCRIPT_CLOUD`                      | Cloud provider (aws, gcp, azure).                                                                           | `-`               |
| `LIBSCRIPT_DOMAIN`                     | The domain name for the certificate.                                                                        | `-`               |
| `CERT_STORE_DIR`                       | Persistent read-only directory on attached storage for storing Let's Encrypt certificates.                  | `/mnt/data/certs` |
| `LETSENCRYPT_EMAIL`                    | Contact email address for Let's Encrypt ACME registration.                                                  | `-`               |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
