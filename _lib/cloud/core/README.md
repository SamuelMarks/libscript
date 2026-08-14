# Cloud

The `cloud` component provides a unified multicloud interface for managing resources across various
cloud providers (AWS, Azure, GCP).

## Usage

```sh
./libscript.sh cloud <provider> <resource> <action> [args...]
```

For high-level provisioning and deprovisioning:

```sh
./libscript.sh provision [--tpu] [--shared-storage] <provider> <node_name> <rg_or_vpc> <region_or_zone> [local_repo_path] [remote_dest]
./libscript.sh deprovision [--tpu] [--shared-storage] [--retain-ip] [--retain-data] <provider> <node_name> <rg_or_vpc> <region_or_zone> [local_repo_path] [remote_dest]
```

### High-Level Orchestrator Flags

- `--tpu` / `--accelerator`: Routes the deployment to utilize specialized TPU VM components (e.g.
  `gcp/tpu-vm`), attaching the necessary network topology, queue pooling, and concurrent pod syncing
  operations natively.
- `--shared-storage`: When passed alongside `--tpu`, provisions and automatically mounts
  high-throughput NFS/Shared Disk arrays (e.g., GCP Filestore) across all cluster workers.
- `--retain-ip`: Prevents the release of static IPs during a `deprovision` action.
- `--retain-data`: Prevents the deletion of persistent stateful data disks during a `deprovision`
  action.

### Providers

- `aws`
- `azure`
- `gcp`

### Resources

- `dns`, `network`, `firewall`, `node`, `node-group`, `jumpbox`, `storage`, `cron`

### Node Actions

- `create`, `list`, `delete`, `exec`, `winrm-exec`
- `deploy` (intelligent codebase sync honoring `.gitignore`, prefers `rsync`, falls back to `scp`,
  supports `winrm` for Windows nodes)
- `scp`, `scp-from`, `winrm-cp`, `winrm-cp-from` (File transfer)
- `snapshot`, `restore` (State management)

### DNS Actions

- `map-node` (Map a running node's public IP to a DNS A record via Cloud DNS / Route53 / Azure DNS)

### Tagging Options

You can control resource tagging during `create` operations:

- `--tags <T>`: Add custom tags.
- AWS: `Key=Project,Value=Postgres15`
- Azure: `Project=Postgres15`
- GCP: `project=postgres15`
- `--no-default-tags`: Disable the default `ManagedBy=LibScript` tag.

## Authentication

LibScript uses native CLIs (`aws`, `az`, `gcloud`) under the hood. Before provisioning
infrastructure, authenticate with your chosen provider using their standard commands (e.g.,
`aws configure`, `az login`, `gcloud auth login`).

See [DOCS.md](./DOCS.md#initial-authentication-setup) for detailed authentication setup options
(Interactive and CI/CD modes).

## Global Management Commands

### Remote State Locking

When working in a team, LibScript can lock your multicloud state file to prevent concurrent
destructive operations. Supported remote backends include AWS S3 (with DynamoDB mock tracking for
locks), Azure Blob Storage (using Leases), and Google Cloud Storage (using Object Locks).

```sh
export REMOTE_STATE_URI="s3://my-team-bucket/libscript_state"
# Any mutating command will now acquire a lock, pull the state, execute, push the state, and release the lock.
./libscript.sh cloud aws node create my-node
```

### View managed resources

```sh

./libscript.sh cloud list-managed

./libscript.sh cloud list-managed Project=Postgres15
```

### Drift Detection

Detect discrepancies between your local `.libscript_state.json` and actual cloud reality (e.g.,
resources manually deleted, or untracked resources provisioned without a state file):

```sh
./libscript.sh cloud diff
```

### Backup

Backup application state (files and databases) locally or to remote object storage, and optionally
take cloud-native volume snapshots:

```sh
# Local backup keeping the last 5
./libscript.sh cloud backup my-node --target local --keep-last 5

# S3 backup with cloud-native snapshot
./libscript.sh cloud backup my-node --target s3 --snapshot
```

### Global Cleanup

```sh

./libscript.sh cloud cleanup

./libscript.sh cloud cleanup Project=Postgres15
```

### Deprovisioning (with Retention)

You can tear down a node but optionally retain its IP address or Data volume so they can be
reattached to a new instance later:

```sh
# Retain IP address (detaches EIP/PIP/Static IP instead of deleting)
./libscript.sh cloud deprovision aws my-node my-vpc us-east-1 --retain-ip

# Retain data disk
./libscript.sh cloud deprovision azure my-node my-rg eastus --retain-data
```

## Example: Project-Specific Deployment

```sh

./libscript.sh cloud aws node-group create my-nodes 3 ami-ubuntu-lts my-vpc \
 --tags "Key=Project,Value=Alpha" \
 --bootstrap "libscript.sh install nginx"

./libscript.sh cloud list-managed Project=Alpha

./libscript.sh cloud cleanup Project=Alpha
```

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->
