# Cloud Wrapper

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
- `network`, `firewall`, `node`, `node-group`, `jumpbox`, `storage`, `cron`

### Tagging Options

You can control resource tagging during `create` operations:

- `--tags <T>`: Add custom tags.
  - AWS: `Key=Project,Value=Postgres15`
  - Azure: `Project=Postgres15`
  - GCP: `project=postgres15`
- `--no-default-tags`: Disable the default `ManagedBy=LibScript` tag.

## Global Management Commands

### View managed resources
```sh
# View all default managed resources
./libscript.sh cloud list-managed

# View resources for a specific project tag
./libscript.sh cloud list-managed Project=Postgres15
```

### Global Cleanup
```sh
# Delete all resources tagged with default LibScript tag
./libscript.sh cloud cleanup

# Delete all resources for a specific project
./libscript.sh cloud cleanup Project=Postgres15
```

## Example: Project-Specific Deployment

```sh
# 1. Provision a project-specific node-group
./libscript.sh cloud aws node-group create my-nodes 3 ami-ubuntu-lts my-vpc \
  --tags "Key=Project,Value=Alpha" \
  --bootstrap "libscript.sh install nginx"

# 2. List only Alpha project resources
./libscript.sh cloud list-managed Project=Alpha

# 3. Clean up only Alpha project resources
./libscript.sh cloud cleanup Project=Alpha
```
