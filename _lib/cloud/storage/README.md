# Cloud Object Storage

The `storage` component provides a unified multicloud interface for managing object storage buckets
(S3, GCS, Azure Blob).

## Usage

```sh
libscript storage [create|delete|list|sync] [--cloud aws|gcp|azure] [--bucket name] [--local-dir path] [--public-web]
```

### Commands

- `create`: Provision a new object storage bucket.
- `delete`: Delete an existing object storage bucket.
- `list`: List managed object storage buckets.
- `sync`: Sync a local directory to an object storage bucket.
