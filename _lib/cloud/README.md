Cloud
=====

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
