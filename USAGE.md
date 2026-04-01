# Usage Guide

This guide provides basic instructions for utilizing the LibScript CLI to provision software and generate artifacts.

## Native Component Installation

To install a tool natively, bypassing containerization, use the `install` subcommand:

```sh
./libscript.sh install nodejs 20
./libscript.sh install rust latest
```

## Declarative Stack Building

You can define a stack's requirements in a `libscript.json` file. The framework will resolve the necessary inter-component dependencies.

Example `libscript.json` for a basic web stack:

```json
{
  "deps": {
    "httpd": "latest",
    "mariadb": "latest",
    "php": "8.2"
  }
}
```

To provision the stack natively:

```sh
./libscript.sh apply
```

## Artifact Generation

To generate artifacts from a component or stack, utilize the `package_as` subcommand.

Generate a Dockerfile:

```sh
./libscript.sh package_as docker
```

Generate a Windows installer (requires appropriate toolchain if built on Linux):

```sh
./libscript.sh package_as msi
```

## Cloud Provisioning

LibScript includes a unified `cloud` wrapper for managing infrastructure across major cloud providers (AWS, Azure, GCP).

### Quickstart

```sh
# Create a Jump-box on AWS
./libscript.sh cloud aws jumpbox create my-jumpbox ami-0c55b159cbfafe1f0

# List all resources created by LibScript across all clouds
./libscript.sh cloud list-managed

# Safety-first cleanup (preserves storage buckets)
./libscript.sh cloud cleanup

# Full cleanup (purges everything including storage)
./libscript.sh cloud cleanup --force-buckets
```

### Dry Run Testing

You can test your cloud commands without real credentials by setting `DRY_RUN=true`.

```sh
export DRY_RUN=true
./libscript.sh cloud gcp storage list
```

## PaaS & High-Level Orchestration

LibScript can orchestrate complex stacks involving multiple nodes and scheduled tasks.

### Node-Group Provisioning
Create a loose collection of nodes bootstrapped with LibScript components.

```sh
# Provision 5 independent nodes with Postgres pre-installed
./libscript.sh cloud aws node-group create pg-nodes 5 ami-ubuntu-lts my-vpc \
  --bootstrap "libscript.sh install postgres latest"
```

### Scheduled Maintenance (Cron)
Set up recurring tasks (like backups) across your managed nodes.

```sh
# Schedule 2-hour backups to S3 on a specific node
./libscript.sh cloud aws cron create pg-nodes-1 '0 */2 * * *' \
  "libscript.sh backup-s3 run my-backups"
```

For advanced configuration options, see the specific module documentation in `_lib/cloud/DOCS.md`.
