# Cloud SSL Certificates

The `cert` component provides a unified multicloud interface for requesting and managing managed SSL
certificates.

> **Note**: This component is an adapter-only cloud wrapper; it manages cloud SSL certificate
> resources via provider APIs and does not provide local `setup.sh`/`env.sh` binary installer
> lifecycles.

## Usage

```sh
libscript cert [create|delete|list] [--cloud aws|gcp|azure] [--domain name]
```

### Commands

- `create`: Request a new managed SSL certificate for a domain.
- `delete`: Delete an existing managed SSL certificate.
- `list`: List managed SSL certificates.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default           | Aliases/Examples |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ----------------- | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `none`            |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `none`            |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `none`            |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `none`            |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `none`            |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `none`            |                  |
| `LIBSCRIPT_CLOUD`                      | Cloud provider (aws, gcp, azure).                                                                           | `none`            |                  |
| `LIBSCRIPT_DOMAIN`                     | The domain name for the certificate.                                                                        | `none`            |                  |
| `CERT_STORE_DIR`                       | Persistent read-only directory on attached storage for storing Let's Encrypt certificates.                  | `/mnt/data/certs` |                  |
| `LETSENCRYPT_EMAIL`                    | Contact email address for Let's Encrypt ACME registration.                                                  | `none`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
