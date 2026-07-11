# GCP Filestore Component

The `filestore` component manages Google Cloud Filestore (NFS) instances, providing high-throughput
shared storage for multi-node clusters (such as TPU Pods).

## Usage

```sh
./libscript.sh gcp/filestore <action> [args...]
```

### Actions

- `create <name>`: Provisions a new GCP Filestore instance named `<name>`.
- `delete <name>`: Deletes the GCP Filestore instance named `<name>`.

## Environment Variables

Configure the `filestore` component via `libscript.json` or by setting the following environment
variables:

- `GCP_PROJECT_ID` (String): The ID of the GCP project where the Filestore should be created.
- `FILESTORE_ZONE` (String): The GCP zone (e.g., `us-central2-b`) where the Filestore instance
  should reside. Must match your compute zone.
- `FILESTORE_TIER` (String): The performance tier for the Filestore instance. Defaults to
  `BASIC_HDD`.
- `FILESTORE_CAPACITY_GB` (String): The capacity of the Filestore instance in gigabytes. Defaults to
  `1024`.
- `FILESTORE_NETWORK` (String): The VPC network to attach the Filestore instance to. Defaults to
  `default`.
