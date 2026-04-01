# Platform-as-a-Service (PaaS) Engine

LibScript is evolving from a provisioning framework into a complete, multicloud Platform-as-a-Service (PaaS). It bridges the gap between infrastructure-as-code and application deployment.

## Current Capabilities

- **Infrastructure Orchestration:** Native support for provisioning compute, network, and storage resources across AWS, Azure, and GCP via a unified CLI.
- **Node-Group Management:** Provision groups of independent nodes and automatically bootstrap them with LibScript components.
- **Granular Database Brokering:** Automatically provision and configure database servers (e.g., Postgres, MariaDB) as part of a stack.
- **Sidecar Services:** Integrated support for background tasks, logging (FluentBit), and monitoring.
- **Scheduled Maintenance:** Built-in `cron` resource type for managing recurring tasks like off-site backups to object storage.
- **Artifact Export:** Deploy stacks as native services, containers, or standalone installers.

## Evolution Plan

### Step 1: Application Specification & Manifests (Implemented)
Utilize `libscript.json` and component `vars.schema.json` to define complex requirements.

### Step 2: Dynamic Routing & Reverse Proxy (Ongoing)
Expand support for Caddy and Nginx with automated API-based configuration for side-by-side app deployments.

### Step 3: Multicloud Convergence (Implemented)
Unified `cloud` wrapper with resource tagging and filtered cleanup.

### Step 4: Process Isolation
Utilizing `systemd` on Linux and native services on Windows/macOS to provide sandboxed execution without virtualization overhead.

### Step 5: The "Dokku-like" Experience
Implementing higher-level `deploy` commands that chain infrastructure provisioning with application bootstrapping.

### Step 6: Web Management Dashboard
Planned lightweight API server to provide a visual interface for managing managed cloud resources and local stacks.
