# Single-Host PaaS Evolution Plan

This document outlines a 7-step plan to evolve the current `libscript` deployment framework into a fully-featured, single-host Platform as a Service (PaaS). The PaaS will support side-by-side application deployments via subdomains, paths, or ports, provide intelligent database brokering, and offer both a Dokku-like CLI and a cPanel-like Web UI.

## Step 1: Application Specification & Manifests
**Goal:** Define a standard schema (e.g., `app.schema.json` or a `Procfile`/`app.yaml` equivalent) that describes an application's infrastructure requirements.
*   **Routing Definition:** Allow applications to define their desired exposure (e.g., `type: subdomain, value: wordpress0.example.com` or `type: path, value: example.com/wordpress1`).
*   **Resource Requirements:** Specify dependencies such as programming language toolchains (`_toolchain/php`), daemons (`_daemon/systemd`), and storage (`_storage/postgres`).
*   **Environment Variables:** Define standard environment variable templates injected into the app at runtime.

## Step 2: Dynamic Routing & Reverse Proxy
**Goal:** Implement a centralized router that dynamically exposes internal applications to the outside world without downtime.
*   **Proxy Engine:** Utilize Caddy (due to its native API and automatic HTTPS) or Nginx (dynamically reloading configurations) from `_server/`.
*   **Path & Subdomain Mapping:** Build logic to map external requests (`example.com/odoo0` or `odoo0.example.com`) to internal ports (e.g., `localhost:8080`) or Unix domain sockets.
*   **Port Management:** Create an internal port allocator to assign unique internal ports to each application dynamically, avoiding collisions.

## Step 3: Database Brokering & State Management
**Goal:** Handle the provisioning, reuse, and augmentation of databases across multiple applications safely.
*   **Database Providers:** Extend `_storage/postgres`, `mariadb`, etc., with "Broker" scripts.
*   **Provisioning Strategies:**
    *   *Shared Instance:* Connect as a superuser to an existing database server and automatically execute `CREATE ROLE` and `CREATE DATABASE` for the new app.
    *   *Dedicated Instance:* Spin up a completely isolated database process/container if strict isolation is required.
*   **Credential Injection:** Automatically inject database credentials into the app's environment via a standardized `DATABASE_URL`.

## Step 4: Process Isolation & Execution Environments
**Goal:** Run application instances safely side-by-side on the same host.
*   **Native Isolation (Systemd):** Utilize advanced `systemd` features (`DynamicUser`, `PrivateTmp`, `ProtectSystem`) to sandbox applications natively without virtualization overhead.
*   **Container Isolation (Docker):** Optionally hook into `_server/docker` to wrap applications in containers, linking them to the host's networking and database layers.
*   **Lifecycle Management:** Implement standardized `start`, `stop`, `restart`, and `status` hooks for every application instance.

## Step 5: The CLI Interface (The "Dokku" Experience)
**Goal:** Build a robust, developer-friendly command-line tool to manage the PaaS.
*   **Core Commands:** Implement commands like `paas app:create myapp`, `paas domains:add myapp myapp.example.com`, and `paas db:link myapp-db myapp`.
*   **Git Deployment:** Create a `gitreceive` hook (building on `_git/`) that allows developers to deploy by running `git push paas master`.
*   **Log Streaming:** Implement `paas logs myapp` to stream real-time logs from the application's underlying daemon or container.

## Step 6: The Web Interface (The "cPanel" Experience)
**Goal:** Provide a graphical dashboard for users who prefer visual management over a CLI.
*   **API Layer:** Build a lightweight API server (e.g., in Go, Python, or Node.js) that acts as a wrapper around the CLI commands, executing them securely.
*   **Dashboard Features:** Allow users to view active apps, monitor resource usage, configure domains/paths, provision databases, and review logs directly from the browser.
*   **Authentication & Access Control:** Ensure the Web UI is secured, potentially supporting multiple users with isolated application environments.

## Step 7: CI/CD & Automated Hooks
**Goal:** Automate the build, test, and release cycle within the PaaS.
*   **Buildpacks / Native Builds:** Integrate a system to automatically detect the application type (Node.js, PHP, Rust) and compile it using the existing `_toolchain/` scripts.
*   **Zero-Downtime Deployments:** Implement blue/green deployment logic. Start a new instance of the app, wait for a health check to pass, update the dynamic router (Step 2), and then spin down the old instance.
*   **Rollbacks:** Keep track of previous deployments (via Git commits or filesystem snapshots) to allow instantaneous rollbacks if an app crashes upon deployment.
