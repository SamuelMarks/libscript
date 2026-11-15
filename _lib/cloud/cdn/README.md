# Cloud CDN

The `cdn` component provides a unified multicloud interface for managing content delivery networks
and edge caching.

> **Note**: This component is an adapter-only cloud wrapper; it interacts directly with cloud APIs
> (AWS CloudFront, GCP Cloud CDN, Azure CDN) and does not provide local `setup.sh`/`env.sh` binary
> installer lifecycles.

## Usage

```sh
libscript cdn [create|delete|list|invalidate] [--cloud aws|gcp|azure] [--bucket name] [--domain custom.tld] [--cert-id id] [--dist-id id] [--paths "/*"]
```

### Commands

- `create`: Provision a CDN distribution pointing to an object storage bucket.
- `delete`: Delete an existing CDN distribution.
- `list`: List managed CDN distributions.
- `invalidate`: Invalidate the edge cache for specified paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                 | Default | Aliases/Examples |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------- | ---------------- |
| `LIBSCRIPT_TAG_ENABLE`                 | Flag (0 or 1) enabling resource tagging on cloud provider assets.                                           | `none`  |                  |
| `LIBSCRIPT_TAG_KEY`                    | Tag key applied to provisioned cloud provider resources.                                                    | `none`  |                  |
| `LIBSCRIPT_TAG_VALUE`                  | Tag value applied to provisioned cloud provider resources.                                                  | `none`  |                  |
| `LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION` | Flag (0 or 1) allowing cloud provider teardown operations to modify resources without matching tag filters. | `none`  |                  |
| `LIBSCRIPT_EXPORT_STAGE_DIR`           | Staging directory used when exporting application and database state archives.                              | `none`  |                  |
| `LIBSCRIPT_IMPORT_STAGE_DIR`           | Staging directory used when importing application and database state archives.                              | `none`  |                  |
| `LIBSCRIPT_CLOUD`                      | Cloud provider (aws, gcp, azure).                                                                           | `none`  |                  |
| `LIBSCRIPT_BUCKET`                     | The name of the object storage bucket acting as origin.                                                     | `none`  |                  |
| `LIBSCRIPT_DOMAIN`                     | Custom domain for the CDN.                                                                                  | `none`  |                  |
| `LIBSCRIPT_CERT_ID`                    | SSL certificate identifier for custom domains.                                                              | `none`  |                  |
| `LIBSCRIPT_DIST_ID`                    | CDN distribution ID (e.g. for delete or invalidate).                                                        | `none`  |                  |
| `LIBSCRIPT_PATHS`                      | Paths to invalidate on the CDN.                                                                             | `none`  |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
