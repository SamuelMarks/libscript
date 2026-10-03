# Architecture: Logical Provisioning & User Configuration

## Overview
LibScript utilizes `MsiEmbeddedChainer` and `msi-rs` to provide zero-.exe physical component chaining. However, enterprise applications (Open edX, WordPress, Odoo) require more than just installing physical binaries (like MySQL or Nginx). They require **Logical Provisioning**: creating specific databases, isolating runtimes via virtual environments, and mapping virtual hosts.

This document describes how LibScript overlays Logical Provisioning on top of shared physical components, allowing side-by-side isolated applications and seamless user configuration (such as choosing a remote database).

## Logical Resources (The Schema)
In `execution-plan.schema.json`, tasks can define `"logical_resources"`. These instruct the installer to configure an isolated space within a shared physical component.

- **`virtual_hosts`**: Instructs the provisioning engine to inject an abstracted reverse proxy configuration into the shared web server (Nginx or Apache httpd). The abstract definition maps `server_name`, `listen_ports`, `routes`, and `document_root` into a generalized format. These are processed dynamically at provisioning time, generating idempotent block replacements in the web server's native configuration format. Engine-specific features are supported via `provider_overrides`.
- **`logical_databases`**: Instructs the provisioning engine to connect to the shared physical database engine (e.g., PostgreSQL) and execute `CREATE DATABASE` and `CREATE USER` commands safely.
- **`runtime_isolation`**: Instructs the provisioning engine to invoke a shared language runtime (e.g., Python 3.11) and spawn an isolated sandboxed environment (`python -m venv`) exclusively for the consumer application.

These logical operations are designed to be strictly **idempotent**, meaning they verify state (e.g., `SELECT 1 FROM pg_database WHERE datname='...'`) before attempting creation, ensuring robust failure recovery.

## Reverse Proxy Abstraction & Multiplexing
LibScript provisions reverse proxies generically. An application (like WordPress) simply states it needs a virtual host for `cms.example.com` routing to its `document_root` or fastcgi socket. 

1. **Proxy Selection**: The installer respects a `preferred_reverse_proxy` configuration (defaulting to Nginx). The user can select Nginx or Apache httpd at install time.
2. **Idempotent Interpolation**: Provisioning scripts (`provision_vhost_abstract.sh` and `.cmd`) parse the abstract rules and template them into the chosen server's native syntax. Changes are applied idempotently using boundary markers (e.g., `# BEGIN libscript-managed: wordpress`) directly into shared configuration files or directories defined by `os-config.schema.json`.
3. **Safety First**: To protect side-by-side installations sharing the same multiplexed web server, configuration syntax tests (`nginx -t` or `httpd -t`) are strictly executed before invoking a reload. Bad interpolations are automatically rolled back without disrupting other hosted applications.
4. **Collision Prevention**: For `msi-rs`, deterministic Component GUIDs (`vhost_components` in `guid_registry.schema.json`) map to specific `server_name` + `app_id` pairs to guarantee that uninstalling one application's routing rules does not orphan or overwrite another's.

## User Configuration & Remote Overrides
In enterprise deployments, a user might already have a managed AWS RDS instance or a pre-configured remote server, rendering local database installation unnecessary. 

LibScript handles this via `"configuration_parameters"` mapped to native MSI properties:

1. **User Interface (`msi-rs`)**: The master MSI displays a dialog offering "Local" vs "Remote" database provisioning.
2. **Property Mapping**: If the user selects "Remote" and enters a host (e.g., `db.example.com`), these map to public properties like `[USER_DB_HOST]` and `[USER_DB_STRATEGY]`.
3. **Chainer Bypass**: `MsiEmbeddedChainer` dynamically reads `[USER_DB_STRATEGY]`. If "remote", it completely skips the execution of the physical `libscript-mysql.msi`.
4. **Parameter Injection**: The logical provisioning scripts (e.g., `provision_logical_db.cmd`) receive these MSI properties as command-line arguments (e.g., `--host "[USER_DB_HOST]"`).
5. **Conditional Execution**: The script verifies the remote connection but skips `CREATE DATABASE` on remote managed systems if it lacks administrative privileges, assuming the DBA pre-provisioned the schema.

## Uninstall and Rollback
When an application (e.g., WordPress) is uninstalled, its logical schemas are dropped (e.g., `DROP DATABASE wp_data`), and its virtual host is unlinked. The physical shared database engine remains running, as its Windows Installer reference count only decrements by 1 (preserving access for Odoo or Open edX). 

If a remote database was used, the uninstall Custom Action respects the configuration state and safely bypasses `DROP DATABASE` on external infrastructure.
