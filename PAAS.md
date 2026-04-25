# Platform-as-a-Service (PaaS) Engine

LibScript is evolving from a provisioning framework into a complete, multicloud Platform-as-a-Service (PaaS). It bridges the gap between infrastructure-as-code and application deployment through its "Every-Thing-is-a-Package-Manager" philosophy.

## Architectural Transition

The core shift is from a system that merely executes scripts to an orchestration layer that manages the entire lifecycle of a stack. By treating every component (databases, runtimes, proxies) as an autonomous, self-healing package manager, LibScript provides a decentralized PaaS experience that can run on any infrastructure—from a single laptop to a distributed multicloud cluster.

## PaaS Capabilities

- **Multicloud Orchestration:** Native support for provisioning compute, network, and storage resources across AWS, Azure, and GCP via a unified, provider-agnostic interface. Features robust cascade deprovisioning to cleanly remove orphaned resources (Disks, NICs, IPs).
- **Intelligent Application Deployment:** The `deploy` engine utilizes `.gitignore`-aware synchronization (preferring `rsync`, falling back to native `scp`, and automatically supporting `winrm` for Windows nodes). This same robust protocol logic is mirrored to the underlying `node scp` and `node scp-from` commands, ensuring state sync operations securely inherit the `rsync` speeds when transferring mutated data during deployments and teardowns.
- **Declarative DNS Management:** Seamlessly maps dynamically provisioned node IPs to fully qualified domains using native Cloud DNS providers (Route53, Azure DNS, Google Cloud DNS), unlocking seamless Let's Encrypt TLS provisioning.
- **Dynamic Stack Resolution:** Automated resolution of complex dependency trees and version constraints using an integrated constraint-solving engine.
- **Zero-Trust Sidecar Services:** Integrated support for background tasks, logging (FluentBit), and monitoring without requiring a global management agent.
- **Automated Reverse Proxying:** Built-in support for Caddy and Nginx with automated, manifest-driven configuration for routing and TLS.
- **Native Auto-Daemonization:** Utilizing native OS primitives (`systemd` on Linux, `launchd` on macOS, and task proxies on Windows) to provide isolation without virtualization overhead. The `services` block automatically templates and enables background units.
- **Declarative Ingress & Hooks:** The `libscript.json` schema natively supports `ingress` blocks for auto-configuring reverse proxies (Nginx + Let's Encrypt), and lifecycle `hooks` for automated ETL, database migrations, and frontend builds.
- **Flexible Deployment Targets:** Stacks can be deployed as native system services, generated into `docker-compose` manifests, or bundled into standalone native installers.

## Roadmap to Maturity

### Phase 1: Declarative Stack Manifests (Implemented)
Utilize `libscript.json` and component schemas to define and enforce the entire application state.

### Phase 2: High-Level `deploy` Engine (Implemented)
Implementing a unified `deploy` command that chains infrastructure provisioning, dependency resolution, and service bootstrapping into a single atomic operation.

### Phase 3: Global State Management (Ongoing)
Development of a lightweight, distributed state store to track managed resources across multiple cloud providers and local nodes.

### Phase 4: Edge-First Management Interface
A decentralized management CLI and optional web dashboard for monitoring stack health and orchestrating updates across the fleet.


## Automated Orchestration

LibScript includes high-level wrapper scripts that automate the entire lifecycle (provisioning network, firewall, VM, syncing code, deploying secrets, configuring DNS, and starting the daemonized stack) for any supported cloud provider.

### Deployment

```bash
# Linux/macOS
# syntax: deploy_cloud.sh <provider> <node_name> <rg/vpc/project> <region/zone> [repo_path] [remote_dest]

# Windows
# syntax: deploy_cloud.bat <provider> <node_name> <rg/vpc/project> <region/zone> [repo_path] [remote_dest]

# Azure <provider> <node_name> <rg/vpc/project> <region/zone> [repo_path] [remote_dest]

# Azure
./scripts/deploy_cloud.sh azure t1d-web-node t1d-rg eastus ./ t1d-analytics
# Windows: .\scripts\deploy_cloud.bat azure t1d-web-node t1d-rg eastus . t1d-analytics

# AWS
./scripts/deploy_cloud.sh aws t1d-web-node t1d-vpc us-east-1 ./ t1d-analytics
# Windows: .\scripts\deploy_cloud.bat aws t1d-web-node t1d-vpc us-east-1 . t1d-analytics

# GCP
./scripts/deploy_cloud.sh gcp t1d-web-node t1d-project us-central1-a ./ t1d-analytics
# Windows: .\scripts\deploy_cloud.bat gcp t1d-web-node t1d-project us-central1-a . t1d-analytics
```

### Deprovisioning

To completely tear down the application and its infrastructure (including DNS A-records, orphan OS Disks, and Network Interfaces):

```bash
# Linux/macOS
# syntax: teardown_cloud.sh <provider> <node_name> <rg/vpc/project> <region/zone> [repo_path] [remote_dest]

# Windows
# syntax: teardown_cloud.bat <provider> <node_name> <rg/vpc/project> <region/zone> [repo_path] [remote_dest]

# Azure <provider> <node_name> <rg/vpc/project> <region/zone> [repo_path] [remote_dest]

# Azure
./scripts/teardown_cloud.sh azure t1d-web-node t1d-rg eastus ./ t1d-analytics
# Windows: .\scripts\teardown_cloud.bat azure t1d-web-node t1d-rg eastus . t1d-analytics

# AWS
./scripts/teardown_cloud.sh aws t1d-web-node t1d-vpc us-east-1 ./ t1d-analytics
# Windows: .\scripts\teardown_cloud.bat aws t1d-web-node t1d-vpc us-east-1 . t1d-analytics

# GCP
./scripts/teardown_cloud.sh gcp t1d-web-node t1d-project us-central1-a ./ t1d-analytics
# Windows: .\scripts\teardown_cloud.bat gcp t1d-web-node t1d-project us-central1-a . t1d-analytics
```

### Infrastructure-as-Code Declarations

You can embed `infrastructure` requirements directly inside your `libscript.json` to prevent hardcoding VM sizes or image names:

```json
{
  "infrastructure": {
    "node": {
      "os": "Ubuntu2204",
      "size": "Standard_B2s",
      "disk_gb": 128
    },
    "network": {
      "ports": [22, 80, 443, 8080]
    }
  }
}
```

### Secrets Provisioning

The deploy script natively supports transferring ignored secret folders. If your `libscript.json` defines `"secrets_dir": "./secrets"`, the orchestration engine will use the `scp` fallback (or `winrm-cp` on Windows nodes) to push these files directly to the remote node before starting the stack, ensuring your git-ignored `.env` variables are correctly provisioned without `rsync` exclusions blocking them.


### Cross-Cloud Infrastructure Sizing
You can embed generic or Azure-native sizing paradigms in `libscript.json`, and the automated multicloud orchestration engine will actively translate them across providers:

```json
{
  "infrastructure": {
    "node": {
      "size": "Standard_D4s_v3",
      "disk_gb": 128
    }
  }
}
```

**Automated Translations (Examples):**
- `Standard_B2s` → `t3.medium` (AWS) → `e2-medium` (GCP)
- `Standard_D4s_v3` → `t3.xlarge` (AWS) → `e2-standard-4` (GCP)

For disk space, the `--os-disk-size-gb` mapping is also translated seamlessly underneath the hood by the individual cloud CLI primitives.

### Avoiding Ephemeral Data Loss (Generic State Backup)
For workloads relying on local state (like DuckDB, SQLite, or file uploads), `libscript` natively supports generic bidirectional state synchronization backed by Object Storage.

Define your state paths and target bucket in `libscript.json`:
```json
{
  "state": {
    "paths": ["t1d.duckdb", "data/"],
    "bucket": "s3://my-bucket/state-backup",
    "endpoint": "https://my-minio-or-r2-endpoint.com"
  }
}
```

#### Supported Protocols
LibScript's sync engine is fully generic and extends far beyond standard AWS/GCP/Azure buckets:
- **Generic S3-Compatible (`s3://`)**: Using the `endpoint` key, `s3://` mappings can point to Cloudflare R2, MinIO, DigitalOcean Spaces, or Backblaze B2, seamlessly routing via `aws s3 cp --endpoint-url`.
- **Rclone Universal Provider (`rclone://`)**: By specifying `rclone://my-remote:bucket/path`, you immediately unlock support for **50+ cloud providers** natively integrated into `rclone`.
- **Native Providers**: Standard `gs://` (Google Cloud Storage) and `azure://container` (Azure Blob Storage) remain natively supported.

During `deploy`, the framework will pull the state from the remote storage and securely transfer it to the node. During `teardown`, the framework automatically pulls the mutated state back from the node and uploads it securely to the bucket, seamlessly ensuring zero ephemeral data loss.
### Automated Secrets Provisioning
`libscript.json` defines secrets (e.g., `"secrets_dir": "./secrets"`). While the primary `.gitignore`-aware deployment engine correctly skips ignored files to prevent committing secrets to instances via insecure paths, the `deploy_cloud.sh` and `deploy_cloud.cmd` wrappers automatically detect this block and invoke a secure `node scp` operation natively over SSH or WinRM *before* the daemonized stack bootstraps. You do not need to sync secrets out-of-band.

### Automated DNS & Dangling Records Cleanup
The `dns map-node` command dynamically maps instances, supporting Azure DNS, AWS Route53, and Google Cloud DNS out of the box. For AWS, the framework automatically resolves the `AWS_ZONE_ID` via the `aws route53` CLI based on your defined domain.

You **must** invoke `dns unmap-node` (handled automatically by `teardown_cloud.sh`) before tearing down the infrastructure. Failing to do so will result in Subdomain Takeover vulnerabilities once the ephemeral IP is reclaimed by the provider pool.

### Phase 4: Continuous Deployment (CD)
You can seamlessly integrate LibScript's \`provision\` and \`deprovision\` primitives into CI/CD pipelines.

#### GitHub Actions Example (.github/workflows/cd.yml)
```yaml
name: Continuous Deployment

on:
  push:
    branches: ["main"]

jobs:
  deploy-to-azure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
          
      - name: Provision Stack
        run: |
          curl -sSL https://get.libscript.org | sh
          libscript provision azure my-node my-rg eastus . ~/my-app
```

### Robust Deployment Features

The `deploy_cloud` and `teardown_cloud` wrappers include production-grade reliability features:

1. **Automated Provisioning & Retries**: Wraps cloud API calls (which frequently experience transient failures or rate limits) in exponential backoff retry loops.
2. **Status & Health Polling**: Actively polls the remote node for SSH/WinRM readiness before attempting to synchronize files, and polls the application's `/api/` HTTP health endpoint after start to ensure the stack stabilized.
3. **Structured Logging**: All deployment and teardown steps write timestamped audit logs locally to the `logs/` directory (e.g., `logs/provision-<timestamp>.log`).
4. **Idempotent Deprovisioning & State Tracking**: Provisioning operations automatically track created cloud resources (VNETs, Firewalls, Nodes) into a local `.deploy_state` file. The `teardown_cloud` wrapper consumes this state file to safely and idempotently delete exactly what was created, preventing orphaned resources even if initial provisioning partially failed.
5. **Smart Transfer Fallbacks**: File syncing transparently prefers `rsync` for high-performance delta transfers, automatically falling back to `scp` on simpler hosts, and native `WinRM` on Windows instances.
