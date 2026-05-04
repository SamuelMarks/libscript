# Cloud

The `cloud` component provides a unified multicloud interface for managing resources across various cloud providers (AWS, Azure, GCP).

## Usage
```sh
./libscript.sh cloud <provider> <resource> <action> [args...]
```

### Providers
- `aws`
- `azure`
- `gcp`

### Resources
- `dns`, `network`, `firewall`, `node`, `node-group`, `jumpbox`, `storage`, `cron`

### Node Actions
- `create`, `list`, `delete`, `exec`, `winrm-exec`
- `deploy` (intelligent codebase sync honoring `.gitignore`, prefers `rsync`, falls back to `scp`, supports `winrm` for Windows nodes)
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

LibScript uses native CLIs (`aws`, `az`, `gcloud`) under the hood. Before provisioning infrastructure, authenticate with your chosen provider using their standard commands (e.g., `aws configure`, `az login`, `gcloud auth login`). 

See [DOCS.md](./DOCS.md#initial-authentication-setup) for detailed authentication setup options (Interactive and CI/CD modes).

## Global Management Commands
### View managed resources
```sh

./libscript.sh cloud list-managed

./libscript.sh cloud list-managed Project=Postgres15
```

### Global Cleanup
```sh

./libscript.sh cloud cleanup

./libscript.sh cloud cleanup Project=Postgres15
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
- Linux
- macOS
- Windows

## Extended Documentation
Multicloud Wrapper

The `cloud` component in LibScript acts as a high-level orchestrator for infrastructure-as-code across major cloud providers.

## Architecture

The wrapper follows a delegation pattern:
1. `libscript.sh cloud <args>` calls `_lib/cloud/cli.sh`.
2. `_lib/cloud/cli.sh` determines the provider and resource.
3. It then re-invokes `libscript.sh <provider> <args>`, which routes to the specific provider's `cli.sh` (e.g., `_lib/cloud-providers/aws/cli.sh`).

## Initial Authentication Setup

Before running provisioning commands, you must configure the underlying cloud provider's authentication context. LibScript wraps the native provider CLIs (`aws`, `az`, `gcloud`), so their standard configuration mechanics apply seamlessly.

### AWS (Amazon Web Services)
**Method 1: Interactive Login (Local Development)**
```sh
aws configure
```
**Method 2: Environment Variables (CI/CD)**
You can set these natively or pass them via `--AWS_ACCESS_KEY_ID=...` flags.
```sh
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Azure (Microsoft Azure)
**Method 1: Interactive Login (Local Development)**
```sh
az login
az account set --subscription <subscription_id>
```
**Method 2: Service Principal (CI/CD)**
```sh
az login --service-principal -u <app-id> -p <password-or-cert> --tenant <tenant-id>
export AZURE_SUBSCRIPTION_ID="your_subscription_id"
```

### GCP (Google Cloud Platform)
**Method 1: Interactive Login (Local Development)**
```sh
gcloud auth login
gcloud config set project <your_project_id>
```
**Method 2: Service Account (CI/CD)**
```sh
gcloud auth activate-service-account --key-file=/path/to/key.json
export GCP_PROJECT_ID="your_project_id"
```

## Resource Tagging & Management

By default, every resource created via LibScript is automatically tagged with a management label:
- **AWS**: `ManagedBy=LibScript` (via Tags API)
- **Azure**: `ManagedBy=LibScript` (via `--tags`)
- **GCP**: `managed-by=libscript` (via labels)

### Custom Tagging

You can override or append to these tags using:
- `--tags <T>`: Appends custom metadata.
- `--no-default-tags`: Prevents the default management tag from being added.

This flexibility allows for project-level grouping (e.g., `Project=postgrescluster15`), which can then be used for filtered listing and deprovisioning.

## Orchestration Features

### Node-Group Management
The `node-group` command allows for bulk provisioning of independent nodes. This provides the raw infrastructure upon which specialized clusters can be built.

### Bootstrapping (Node Setup)
The `--bootstrap` flag allows passing a shell script that will be executed on the node upon creation via cloud-native mechanisms (`User-Data`, `Custom-Data`, or `Startup-Script`).

### Remote Operations & Execution
The `exec` command provides a way to run shell commands on remote nodes via SSH or cloud-native tools.
For Windows instances, `winrm-exec` utilizes PowerShell Core (`pwsh`) or `winrs` to remotely execute commands via WinRM. Note that `WINRM_PASS` is required, and `WINRM_USER` defaults to `Administrator` (or `libscript` on Azure).

Additionally, you can securely copy files to and from managed nodes:
- `scp <node_name> <local_src> <remote_dest>`: Upload files/directories over SSH.
- `scp-from <node_name> <remote_src> <local_dest>`: Download files/directories over SSH.
- `winrm-cp <node_name> <local_src> <remote_dest>`: Upload files/directories over WinRM using `pwsh`.
- `winrm-cp-from <node_name> <remote_src> <local_dest>`: Download files/directories over WinRM using `pwsh`.

### Node State Management (Snapshots)
Nodes can be backed up and restored via cloud-native image capture (AMIs, Managed Images, Disks/Snapshots).
- `snapshot <node_name> <snapshot_name>`: Generalizes or snapshots the node.
- `restore <node_name> <snapshot_name> <network_id> [args...]`: Deletes the existing node and replaces it with a fresh node provisioned from the snapshot.

### Scheduled Tasks (Cron)
The `cron` resource allows for setting up recurring tasks on managed nodes by updating the target instance's crontab.

## Cleanup and Safety

The `cleanup` command supports filtered deprovisioning:
- **Default**: Deletes all resources with the default LibScript management tag.
- **Filtered**: Provide a tag string (e.g., `Project=Alpha`) to delete only resources matching that metadata.
- **Storage Safety**: Storage buckets are preserved by default unless `--force-buckets` is specified.

## Dry Run Mode

You can test your cloud orchestration logic without incurring costs or needing credentials by setting `DRY_RUN=true`.

```sh
export DRY_RUN=true
./libscript.sh cloud aws node-group create alpha-nodes 3 ami-ubuntu-lts my-vpc \
  --tags "Key=Project,Value=Alpha"
```
