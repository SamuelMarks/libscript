# Cloud CDN

The `cdn` component provides a unified multicloud interface for managing content delivery networks
and edge caching.

## Usage

```sh
libscript cdn [create|delete|list|invalidate] [--cloud aws|gcp|azure] [--bucket name] [--domain custom.tld] [--cert-id id] [--dist-id id] [--paths "/*"]
```

### Commands

- `create`: Provision a CDN distribution pointing to an object storage bucket.
- `delete`: Delete an existing CDN distribution.
- `list`: List managed CDN distributions.
- `invalidate`: Invalidate the edge cache for specified paths.
