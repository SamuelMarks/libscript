# Multicloud Wrapper Technical Documentation

The `cloud` component in LibScript acts as a high-level orchestrator for infrastructure-as-code across major cloud providers.

## Architecture

The wrapper follows a delegation pattern:
1. `libscript.sh cloud <args>` calls `_lib/cloud/cli.sh`.
2. `_lib/cloud/cli.sh` determines the provider and resource.
3. It then re-invokes `libscript.sh <provider> <args>`, which routes to the specific provider's `cli.sh` (e.g., `_lib/cloud-providers/aws/cli.sh`).

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

### Remote Execution (Exec)
The `exec` command provides a way to run shell commands on remote nodes via SSH or cloud-native tools.

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
